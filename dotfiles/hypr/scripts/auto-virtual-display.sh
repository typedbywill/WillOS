#!/usr/bin/env bash

# ==============================================================================
# Auto Virtual Display & Window Rescue Manager for Hyprland
# 
# 1. Cria automaticamente um monitor virtual headless (1920x1080) quando nenhum
#    monitor físico estiver conectado, e remove o monitor virtual automaticamente
#    quando o monitor físico for reconectado.
# 2. Resgata e redireciona automaticamente aplicativos e workspaces para um
#    monitor conectado quando qualquer monitor for desconectado.
# ==============================================================================

export PATH="$PATH:/run/current-system/sw/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin"

PIDFILE="/run/user/$(id -u)/auto-virtual-display.pid"
LOCK_FILE="/run/user/$(id -u)/auto-virtual-display.lock"
TRIGGER_FILE="/run/user/$(id -u)/auto-virtual-display.trigger"

# Garante instância única
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
    exit 0
fi
echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE" "$LOCK_FILE" "$TRIGGER_FILE"' EXIT

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [auto-virtual-display] $*"
}

# Aguarda o Hyprland IPC estar pronto
wait_for_hyprland() {
    local max_attempts=50
    local attempt=0
    while ! hyprctl version >/dev/null 2>&1; do
        sleep 0.1
        attempt=$((attempt + 1))
        if [ "$attempt" -ge "$max_attempts" ]; then
            log "Aviso: Timeout aguardando IPC do Hyprland."
            break
        fi
    done
}

# Reinicia Sunshine para atualizar a captura e lista de monitores
restart_sunshine() {
    log "Reiniciando serviço Sunshine para atualizar lista de monitores..."
    systemctl --user reset-failed sunshine.service 2>/dev/null || true
    systemctl --user restart sunshine.service 2>/dev/null || true
}

# Resgata janelas e workspaces órfãos quando um monitor é desconectado ou quando resta 1 monitor
rescue_orphaned_windows() {
    local monitors_json
    monitors_json=$(hyprctl -j monitors 2>/dev/null)
    [ -z "$monitors_json" ] || [ "$monitors_json" = "[]" ] && return

    local clients_json
    clients_json=$(hyprctl -j clients 2>/dev/null)
    [ -z "$clients_json" ] || [ "$clients_json" = "[]" ] && return

    local workspaces_json
    workspaces_json=$(hyprctl -j workspaces 2>/dev/null)

    # Obter monitor alvo (focado ou primeiro conectado) e seu workspace ativo
    local target_mon target_ws
    target_mon=$(echo "$monitors_json" | jq -r '(.[] | select(.focused == true) | .name) // .[0].name')
    target_ws=$(echo "$monitors_json" | jq -r '(.[] | select(.focused == true) | .activeWorkspace.id) // .[0].activeWorkspace.id')

    if [ -z "$target_mon" ] || [ "$target_mon" = "null" ]; then
        return
    fi

    local num_monitors
    num_monitors=$(echo "$monitors_json" | jq 'length')

    local active_mon_ids active_mon_names
    active_mon_ids=$(echo "$monitors_json" | jq '[.[].id]')
    active_mon_names=$(echo "$monitors_json" | jq '[.[].name]')

    # 1. Resgata workspaces órfãos ou, se houver apenas 1 monitor conectado, transfere todos os workspaces com janelas
    if [ "$num_monitors" -eq 1 ] && [ -n "$workspaces_json" ] && [ "$workspaces_json" != "[]" ]; then
        local all_non_target_ws
        all_non_target_ws=$(echo "$workspaces_json" | jq -r --arg tm "$target_mon" '.[] | select(.id > 0 and .monitor != $tm and .windows > 0) | .id')
        for ws_id in $all_non_target_ws; do
            [ -z "$ws_id" ] && continue
            log "Movendo workspace $ws_id para o único monitor ativo $target_mon..."
            hyprctl dispatch moveworkspacetomonitor "$ws_id" "$target_mon" >/dev/null 2>&1
        done
    elif [ -n "$workspaces_json" ] && [ "$workspaces_json" != "[]" ]; then
        local orphaned_ws_ids
        orphaned_ws_ids=$(echo "$workspaces_json" | jq -r --argjson active_names "$active_mon_names" '
            .[] | select(.id > 0 and (.monitor as $m | ($active_names | index($m)) == null)) | .id
        ')
        for ws_id in $orphaned_ws_ids; do
            [ -z "$ws_id" ] && continue
            log "Movendo workspace órfão $ws_id para o monitor ativo $target_mon..."
            hyprctl dispatch moveworkspacetomonitor "$ws_id" "$target_mon" >/dev/null 2>&1
        done
    fi

    # 2. Resgata janelas que porventura ainda estejam órfãs após a movimentação de workspaces
    local clients_after
    clients_after=$(hyprctl -j clients 2>/dev/null)
    if [ -n "$clients_after" ] && [ "$clients_after" != "[]" ]; then
        local orphaned_addresses
        orphaned_addresses=$(echo "$clients_after" | jq -r --argjson active_ids "$active_mon_ids" '
            .[] | select(.workspace.id > 0 and (.monitor as $m | ($active_ids | index($m)) == null)) | .address
        ')

        for addr in $orphaned_addresses; do
            [ -z "$addr" ] && continue
            log "Movendo janela individual órfã $addr para o workspace ativo $target_ws ($target_mon)..."
            hyprctl dispatch movetoworkspacesilent "$target_ws,address:$addr" >/dev/null 2>&1
        done
    fi
}

# Sincroniza o estado dos monitores
sync_monitors() {
    local monitors_json
    monitors_json=$(hyprctl -j monitors 2>/dev/null)
    
    # Se hyprctl não retornar nada ou array vazio
    if [ -z "$monitors_json" ] || [ "$monitors_json" = "[]" ]; then
        log "Nenhum monitor ativo detectado no Hyprland. Criando monitor virtual 1080p..."
        hyprctl output create headless
        sleep 0.5
        restart_sunshine
        return
    fi

    # Filtra nomes de monitores físicos e virtuais (HEADLESS-* / FALLBACK-*)
    local physical_names=""
    local headless_names=""
    if command -v jq >/dev/null 2>&1; then
        physical_names=$(echo "$monitors_json" | jq -r '.[] | select((.name | startswith("HEADLESS-") or startswith("FALLBACK-")) | not) | .name')
        headless_names=$(echo "$monitors_json" | jq -r '.[] | select(.name | startswith("HEADLESS-") or startswith("FALLBACK-")) | .name')
    elif command -v node >/dev/null 2>&1; then
        physical_names=$(node -e 'JSON.parse(process.argv[1]).filter(m => !m.name.startsWith("HEADLESS-") && !m.name.startsWith("FALLBACK-")).forEach(m => console.log(m.name))' "$monitors_json")
        headless_names=$(node -e 'JSON.parse(process.argv[1]).filter(m => m.name.startsWith("HEADLESS-") || m.name.startsWith("FALLBACK-")).forEach(m => console.log(m.name))' "$monitors_json")
    else
        physical_names=$(echo "$monitors_json" | grep -o '"name": *"[^"]*"' | sed -E 's/.*"name": *"([^"]+)".*/\1/' | grep -v -E '^(HEADLESS-|FALLBACK-)' || true)
        headless_names=$(echo "$monitors_json" | grep -o '"name": *"(HEADLESS-|FALLBACK-)[^"]*"' | sed -E 's/.*"name": *"([^"]+)".*/\1/' || true)
    fi

    local physical_count
    local headless_count
    physical_count=$(echo "$physical_names" | grep -c -v '^$' || true)
    headless_count=$(echo "$headless_names" | grep -c -v '^$' || true)

    if [ "$physical_count" -eq 0 ]; then
        # Sem monitor físico: se ainda não houver nenhum headless, cria um
        if [ "$headless_count" -eq 0 ]; then
            log "Monitor físico desconectado. Criando monitor virtual HEADLESS (1920x1080)..."
            hyprctl output create headless
            sleep 0.5
            rescue_orphaned_windows
            restart_sunshine
        fi
    else
        # Há monitor físico: se houver algum headless ativo, move as janelas para o físico e remove-os
        if [ "$headless_count" -gt 0 ]; then
            for hmon in $headless_names; do
                [ -z "$hmon" ] && continue
                local target_phys
                target_phys=$(echo "$physical_names" | head -n 1)
                log "Movendo workspaces do monitor virtual $hmon para $target_phys..."
                local hmon_workspaces
                hmon_workspaces=$(hyprctl -j workspaces 2>/dev/null | jq -r --arg hm "$hmon" '.[] | select(.monitor == $hm and .windows > 0) | .id')
                for hw in $hmon_workspaces; do
                    [ -z "$hw" ] && continue
                    hyprctl dispatch moveworkspacetomonitor "$hw" "$target_phys" >/dev/null 2>&1
                done
                log "Monitor físico conectado ($physical_names). Removendo monitor virtual $hmon..."
                hyprctl output remove "$hmon"
            done
            sleep 0.5
            rescue_orphaned_windows
            restart_sunshine
        fi
    fi

    # Sempre garante que janelas órfãs sejam resgatadas para os monitores remanescentes
    rescue_orphaned_windows
}

# Agrupa eventos rápidos (debouncing)
trigger_sync() {
    touch "$TRIGGER_FILE"
    (
        flock -n 200 || exit 0
        while [ -f "$TRIGGER_FILE" ]; do
            rm -f "$TRIGGER_FILE"
            sleep 0.2
            sync_monitors
        done
    ) 200>"$LOCK_FILE" &
}

# Aguarda inicialização do Hyprland
wait_for_hyprland

# Verificação inicial na inicialização
sync_monitors

# Garante que o Sunshine tenha o monitor correto e inicializado após o boot
restart_sunshine

# Loop contínuo escutando o socket de eventos do Hyprland
while true; do
    SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
    if [ ! -S "$SOCKET" ]; then
        SOCKET=$(find "$XDG_RUNTIME_DIR/hypr" -name ".socket2.sock" 2>/dev/null | head -n 1)
    fi

    if [ -n "$SOCKET" ] && [ -S "$SOCKET" ]; then
        log "Conectado ao socket de eventos do Hyprland: $SOCKET"
        
        if command -v socat >/dev/null 2>&1; then
            socat -u UNIX-CONNECT:"$SOCKET" - 2>/dev/null | while read -r line; do
                case "$line" in
                    monitoradded*|monitorremoved*)
                        trigger_sync
                        ;;
                esac
            done
        elif command -v nc >/dev/null 2>&1; then
            nc -U "$SOCKET" 2>/dev/null | while read -r line; do
                case "$line" in
                    monitoradded*|monitorremoved*)
                        trigger_sync
                        ;;
                esac
            done
        fi
    fi

    # Se desconectar (ex: reload do Hyprland), aguarda e tenta reconectar
    sleep 2
done

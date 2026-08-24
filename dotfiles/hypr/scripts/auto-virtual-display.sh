#!/usr/bin/env bash

# ==============================================================================
# Auto Virtual Display Manager for Hyprland
# 
# Cria automaticamente um monitor virtual headless (1920x1080) quando nenhum
# monitor físico estiver conectado, e remove o monitor virtual automaticamente
# quando o monitor físico for reconectado.
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
            restart_sunshine
        fi
    else
        # Há monitor físico: se houver algum headless ativo, remove-os
        if [ "$headless_count" -gt 0 ]; then
            for hmon in $headless_names; do
                [ -z "$hmon" ] && continue
                log "Monitor físico conectado ($physical_names). Removendo monitor virtual $hmon..."
                hyprctl output remove "$hmon"
            done
            sleep 0.5
            restart_sunshine
        fi
    fi
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

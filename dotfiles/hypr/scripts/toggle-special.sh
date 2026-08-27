#!/usr/bin/env bash

# ==============================================================================
# Toggle Special Workspace & Application Launcher / Restorer for Hyprland
# 
# Permite abrir / alternar workspaces especiais (ex: communication, music, passwords),
# iniciando o aplicativo automaticamente caso não esteja aberto, e restaurando/desminimizando
# a janela caso esteja oculta na bandeja do sistema.
# ==============================================================================

export PATH="$PATH:/run/current-system/sw/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin"

WORKSPACE="$1"
CLASS_REGEX="$2"
LAUNCH_CMD="$3"
RESTORE_CMD="${4:-$LAUNCH_CMD}"
PROC_PATTERN="${5:-$(echo "$LAUNCH_CMD" | awk '{print $1}')}"

if [ -z "$WORKSPACE" ] || [ -z "$CLASS_REGEX" ]; then
    echo "Uso: $0 <nome_workspace> <regex_classe> <comando_launch> [comando_restore] [padrao_processo]"
    exit 1
fi

run_app() {
    if command -v uwsm >/dev/null 2>&1; then
        uwsm app -- "$@"
    else
        "$@" &
    fi
}

# 1. Verifica se o workspace especial já está visível e focado no monitor atual
MONITORS_JSON=$(hyprctl -j monitors 2>/dev/null)
CURRENT_SPECIAL=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.focused == true) | .specialWorkspace.name // ""')

if [ "$CURRENT_SPECIAL" = "special:$WORKSPACE" ]; then
    # Se já estiver aberto no monitor atual, fecha (comportamento de toggle)
    hyprctl dispatch togglespecialworkspace "$WORKSPACE"
    exit 0
fi

# 2. Se não estiver aberto, verifica se a janela existe na lista de clientes do Hyprland
CLIENTS_JSON=$(hyprctl -j clients 2>/dev/null)
HAS_WINDOW=$(echo "$CLIENTS_JSON" | jq -r --arg pat "$CLASS_REGEX" '[.[] | select(.class | test($pat; "i"))] | length')

if [ "$HAS_WINDOW" = "0" ] || [ -z "$HAS_WINDOW" ]; then
    # Janela não encontrada. Verifica se o processo está em execução (ex: minimizado na bandeja)
    if pgrep -fi "$PROC_PATTERN" >/dev/null 2>&1; then
        if [ -n "$RESTORE_CMD" ]; then
            eval "$RESTORE_CMD" >/dev/null 2>&1 &
        fi
    else
        # Processo não existe, inicia a aplicação
        eval "run_app $LAUNCH_CMD" >/dev/null 2>&1 &
    fi
else
    # Janela existe no Hyprland. Se houver comando específico de restauração/foco, executa
    if [ -n "$RESTORE_CMD" ] && [ "$RESTORE_CMD" != "$LAUNCH_CMD" ]; then
        eval "$RESTORE_CMD" >/dev/null 2>&1 &
    fi
fi

# 3. Abre o workspace especial no monitor focado
hyprctl dispatch togglespecialworkspace "$WORKSPACE"

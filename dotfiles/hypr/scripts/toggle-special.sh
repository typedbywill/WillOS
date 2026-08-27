#!/usr/bin/env bash

# ==============================================================================
# Toggle Special Workspace & Application Launcher for Hyprland
# 
# Permite abrir / alternar workspaces especiais (ex: communication, music, passwords),
# iniciando o aplicativo automaticamente caso não esteja aberto.
# ==============================================================================

export PATH="$PATH:/run/current-system/sw/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin"

WORKSPACE="$1"
CLASS_REGEX="$2"
LAUNCH_CMD="$3"
PROC_PATTERN="${4:-$(echo "$LAUNCH_CMD" | awk '{print $1}')}"

if [ -z "$WORKSPACE" ] || [ -z "$CLASS_REGEX" ]; then
    echo "Uso: $0 <nome_workspace> <regex_classe> <comando_launch> [padrao_processo]"
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
    # Se já estiver aberto no monitor atual, fecha (toggle)
    hyprctl dispatch togglespecialworkspace "$WORKSPACE"
    exit 0
fi

# 2. Se não estiver aberto, verifica se a janela existe no Hyprland
CLIENTS_JSON=$(hyprctl -j clients 2>/dev/null)
HAS_WINDOW=$(echo "$CLIENTS_JSON" | jq -r --arg pat "$CLASS_REGEX" '[.[] | select(.class | test($pat; "i"))] | length')

if [ "$HAS_WINDOW" = "0" ] || [ -z "$HAS_WINDOW" ]; then
    # Verifica se o processo está em execução
    if ! pgrep -fi "$PROC_PATTERN" >/dev/null 2>&1; then
        # Inicia a aplicação se o processo não existir
        eval "run_app $LAUNCH_CMD" >/dev/null 2>&1 &
    else
        # Se o processo estiver ativo mas sem janela (oculto na bandeja), aciona o launcher
        eval "run_app $LAUNCH_CMD" >/dev/null 2>&1 &
    fi
fi

# 3. Abre o workspace especial no monitor focado
hyprctl dispatch togglespecialworkspace "$WORKSPACE"

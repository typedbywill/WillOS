#!/usr/bin/env bash

# ==============================================================================
# Workspace Manager per Monitor for Hyprland
# 
# Permite ter conjuntos de workspaces independentes por monitor (1-10 na tela 1,
# 11-20 na tela 2, 21-30 na tela 3, e assim por diante).
# Ao pressionar SUPER+1..0, a navegação ocorre relativamente ao monitor focado.
# Nenhum nome de conector e' fixado: os monitores sao ordenados pela sua posicao.
# ==============================================================================

export PATH="$PATH:/run/current-system/sw/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin"

ACTION="${1:-switch}" # switch, move, movesilent
NUM="${2:-1}"

if ! [[ "$NUM" =~ ^[0-9]+$ ]]; then
    exit 0
fi

# Mapeia tecla 0 como workspace 10 (após o 9)
if [ "$NUM" -eq 0 ]; then
    NUM=10
fi

# Quantidade de workspaces por monitor
WS_PER_MONITOR=10

if [ "$NUM" -gt "$WS_PER_MONITOR" ]; then
    exit 0
fi

# Obtém os monitores ativos
monitors_json=$(hyprctl -j monitors 2>/dev/null)

if [ -z "$monitors_json" ] || [ "$monitors_json" = "[]" ]; then
    # Fallback se não conseguir consultar monitores
    case "$ACTION" in
        switch) hyprctl dispatch workspace "$NUM" ;;
        move) hyprctl dispatch movetoworkspace "$NUM" ;;
        movesilent) hyprctl dispatch movetoworkspacesilent "$NUM" ;;
    esac
    exit 0
fi

# Obtém o monitor focado e seu índice na disposição atual. A ordem por x/y
# funciona para qualquer nome de conector e mantém a tela mais à esquerda no
# bloco 1-10. Em uma única tela, o índice é sempre 0.
FOCUSED_MON=$(echo "$monitors_json" | jq -r '(.[] | select(.focused == true) | .name) // .[0].name // empty')
MON_IDX=$(echo "$monitors_json" | jq -r --arg name "$FOCUSED_MON" '
    sort_by([.x, .y, .id, .name])
    | map(.name)
    | index($name) // 0
')

if [ -z "$FOCUSED_MON" ] || ! [[ "$MON_IDX" =~ ^[0-9]+$ ]]; then
    exit 0
fi

TARGET_WS=$(( (MON_IDX * WS_PER_MONITOR) + NUM ))

# Garante que o workspace alvo pertença ao monitor focado antes de alternar/mover
hyprctl dispatch moveworkspacetomonitor "$TARGET_WS" "$FOCUSED_MON" >/dev/null 2>&1

case "$ACTION" in
    switch)
        hyprctl dispatch focusmonitor "$FOCUSED_MON" >/dev/null 2>&1
        hyprctl dispatch workspace "$TARGET_WS"
        ;;
    move)
        hyprctl dispatch movetoworkspace "$TARGET_WS"
        ;;
    movesilent)
        hyprctl dispatch movetoworkspacesilent "$TARGET_WS"
        ;;
    *)
        hyprctl dispatch workspace "$TARGET_WS"
        ;;
esac

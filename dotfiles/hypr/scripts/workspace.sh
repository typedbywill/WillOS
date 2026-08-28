#!/usr/bin/env bash

# ==============================================================================
# Workspace Manager per Monitor for Hyprland
# 
# Permite ter conjuntos de workspaces independentes por monitor (ex: 1-5 na tela 1,
# 6-10 na tela 2, 11-15 na tela 3).
# Ao pressionar SUPER+1..5, a navegação ocorre relativamente ao monitor focado.
# ==============================================================================

export PATH="$PATH:/run/current-system/sw/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin"

ACTION="${1:-switch}" # switch, move, movesilent
NUM="${2:-1}"

if ! [[ "$NUM" =~ ^[0-9]+$ ]]; then
    exit 0
fi

# Quantidade de workspaces por monitor (10 workspaces por monitor: 1-10, 11-20, 21-30)
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

# Obtém o monitor focado
FOCUSED_MON=$(echo "$monitors_json" | jq -r '(.[] | select(.focused == true) | .name) // .[0].name // "DP-1"')

# Quantidade de monitores ativos
NUM_MONITORS=$(echo "$monitors_json" | jq 'length')

# Determina o índice base do monitor correspondente às regras do hyprland.conf
if [ "$NUM_MONITORS" -le 1 ]; then
    MON_IDX=0
else
    case "$FOCUSED_MON" in
        DP-1|DP-*)       MON_IDX=0 ;;
        HDMI-A-1|HDMI-*) MON_IDX=1 ;;
        eDP-1|eDP-*)     MON_IDX=2 ;;
        *)
            MON_IDX=$(echo "$monitors_json" | jq -r --arg name "$FOCUSED_MON" 'sort_by(.x) | map(.name) | index($name) // 0')
            ;;
    esac
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

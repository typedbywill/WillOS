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

# Quantidade de workspaces por monitor (padrão 5)
WS_PER_MONITOR=5

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

# Extrai o nome do monitor focado e calcula o workspace de destino ordenado por posição horizontal X
read -r FOCUSED_MON TARGET_WS < <(echo "$monitors_json" | jq -r --argjson num "$NUM" --argjson per_mon "$WS_PER_MONITOR" '
    (sort_by(.x) | to_entries[] | select(.value.focused == true)) as $entry
    | ($entry.key // 0) as $idx
    | ($entry.value.name // "DP-1") as $name
    | "\($name) \((($idx * $per_mon) + $num))"
')

if [ -z "$TARGET_WS" ] || [ "$TARGET_WS" = "null" ]; then
    TARGET_WS="$NUM"
fi

if [ -z "$FOCUSED_MON" ] || [ "$FOCUSED_MON" = "null" ]; then
    FOCUSED_MON=$(echo "$monitors_json" | jq -r '.[0].name // "DP-1"')
fi

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

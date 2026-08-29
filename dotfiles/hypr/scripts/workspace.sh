#!/usr/bin/env bash

# ==============================================================================
# Dynamic Workspace & Active Monitor Manager for Hyprland (WillOS)
# 
# Garante que todos os Workspaces (1..10) e suas aplicações sigam dinamicamente
# o monitor ativo e focado. Ao trocar de monitor ou acionar um workspace, os
# aplicativos acompanham o usuário para a tela em uso.
# ==============================================================================

export PATH="$PATH:/run/current-system/sw/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin"

ACTION="${1:-switch}" # switch, move, movesilent, pull_all, focus_monitor, move_workspace_to_monitor
NUM="${2:-1}"

# Função para obter monitor focado
get_focused_mon() {
    local monitors_json
    monitors_json=$(hyprctl -j monitors 2>/dev/null)
    echo "$monitors_json" | jq -r '(.[] | select(.focused == true) | .name) // .[0].name // ""'
}

case "$ACTION" in
    switch)
        # Mapeia tecla 0 como workspace 10
        if [ "$NUM" -eq 0 ] 2>/dev/null; then
            NUM=10
        fi

        if ! [[ "$NUM" =~ ^[0-9]+$ ]]; then
            exit 0
        fi

        FOCUSED_MON=$(get_focused_mon)

        if [ -n "$FOCUSED_MON" ] && [ "$FOCUSED_MON" != "null" ]; then
            # Move o workspace selecionado para o monitor focado atual
            hyprctl dispatch moveworkspacetomonitor "$NUM" "$FOCUSED_MON" >/dev/null 2>&1
            hyprctl dispatch focusmonitor "$FOCUSED_MON" >/dev/null 2>&1
        fi

        hyprctl dispatch workspace "$NUM"
        ;;

    move)
        if [ "$NUM" -eq 0 ] 2>/dev/null; then
            NUM=10
        fi
        if ! [[ "$NUM" =~ ^[0-9]+$ ]]; then
            exit 0
        fi
        hyprctl dispatch movetoworkspace "$NUM"
        ;;

    movesilent)
        if [ "$NUM" -eq 0 ] 2>/dev/null; then
            NUM=10
        fi
        if ! [[ "$NUM" =~ ^[0-9]+$ ]]; then
            exit 0
        fi
        hyprctl dispatch movetoworkspacesilent "$NUM"
        ;;

    pull_all)
        # Traz todos os workspaces com janelas de outras telas para o monitor focado
        monitors_json=$(hyprctl -j monitors 2>/dev/null)
        FOCUSED_MON=$(echo "$monitors_json" | jq -r '(.[] | select(.focused == true) | .name) // .[0].name // ""')
        ACTIVE_WS=$(echo "$monitors_json" | jq -r '(.[] | select(.focused == true) | .activeWorkspace.id) // .[0].activeWorkspace.id // 1')

        if [ -n "$FOCUSED_MON" ] && [ "$FOCUSED_MON" != "null" ]; then
            workspaces_json=$(hyprctl -j workspaces 2>/dev/null)
            other_ws=$(echo "$workspaces_json" | jq -r --arg mon "$FOCUSED_MON" '.[] | select(.id > 0 and .monitor != $mon and .windows > 0) | .id')
            
            count=0
            for ws in $other_ws; do
                [ -z "$ws" ] && continue
                hyprctl dispatch moveworkspacetomonitor "$ws" "$FOCUSED_MON" >/dev/null 2>&1
                count=$((count + 1))
            done

            # Resgata janelas que possam estar em monitores desconectados ou órfãos
            active_mon_ids=$(echo "$monitors_json" | jq '[.[].id]')
            clients_json=$(hyprctl -j clients 2>/dev/null)
            orphaned_addrs=$(echo "$clients_json" | jq -r --argjson active_ids "$active_mon_ids" '
                .[] | select(.workspace.id > 0 and (.monitor as $m | ($active_ids | index($m)) == null)) | .address
            ')
            for addr in $orphaned_addrs; do
                [ -z "$addr" ] && continue
                hyprctl dispatch movetoworkspacesilent "$ACTIVE_WS,address:$addr" >/dev/null 2>&1
                count=$((count + 1))
            done

            if command -v notify-send >/dev/null 2>&1; then
                notify-send -u low -a "WillOS" -i "preferences-desktop-display" "Monitores" "Aplicativos transferidos para o monitor ativo ($FOCUSED_MON)." 2>/dev/null || true
            fi
        fi
        ;;

    focus_monitor)
        TARGET="${2:-+1}"
        case "$TARGET" in
            next|+1) hyprctl dispatch focusmonitor +1 ;;
            prev|-1) hyprctl dispatch focusmonitor -1 ;;
            *) hyprctl dispatch focusmonitor "$TARGET" ;;
        esac
        ;;

    move_workspace_to_monitor)
        TARGET="${2:-+1}"
        case "$TARGET" in
            next|+1) hyprctl dispatch movecurrentworkspacetomonitor +1 ;;
            prev|-1) hyprctl dispatch movecurrentworkspacetomonitor -1 ;;
            *) hyprctl dispatch movecurrentworkspacetomonitor "$TARGET" ;;
        esac
        ;;

    *)
        hyprctl dispatch workspace "$ACTION"
        ;;
esac

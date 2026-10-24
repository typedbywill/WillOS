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

<<<<<<< Updated upstream
ACTION="${1:-switch}" # switch, move, movesilent, insert, insertsilent
=======
ACTION="${1:-switch}" # switch, send, move, movesilent
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
        move|insert) hyprctl dispatch movetoworkspace "$NUM" ;;
        movesilent|insertsilent) hyprctl dispatch movetoworkspacesilent "$NUM" ;;
=======
        send) hyprctl dispatch movetoworkspace "$NUM" ;;
        move) hyprctl dispatch movetoworkspace "$NUM" ;;
        movesilent) hyprctl dispatch movetoworkspacesilent "$NUM" ;;
>>>>>>> Stashed changes
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
BLOCK_START=$(( (MON_IDX * WS_PER_MONITOR) + 1 ))
BLOCK_END=$(( (MON_IDX * WS_PER_MONITOR) + WS_PER_MONITOR ))

# Envia a janela focada ao workspace alvo sem reordenar os demais: nenhuma
# janela e' empurrada e o foco acompanha a janela movida.
send_window() {
    hyprctl dispatch moveworkspacetomonitor "$TARGET_WS" "$FOCUSED_MON" >/dev/null 2>&1
    hyprctl dispatch movetoworkspace "$TARGET_WS"
}

# ------------------------------------------------------------------------------
<<<<<<< Updated upstream
# Mover somente a janela focada (META+SHIFT+N), sem deslocar outras janelas.
move_focused() {
    local silent="$1" focused_addr final_cmd
    focused_addr=$(hyprctl -j activewindow 2>/dev/null | jq -r '.address // empty')
    [ -n "$focused_addr" ] || return 0

    final_cmd="movetoworkspace"
    [ "$silent" = "1" ] && final_cmd="movetoworkspacesilent"

    if [ "${DRY_RUN:-0}" = "1" ]; then
        printf 'dispatch moveworkspacetomonitor %s %s\n' "$TARGET_WS" "$FOCUSED_MON"
        printf 'dispatch %s %s,address:%s\n' "$final_cmd" "$TARGET_WS" "$focused_addr"
    else
        hyprctl dispatch moveworkspacetomonitor "$TARGET_WS" "$FOCUSED_MON" >/dev/null 2>&1
        hyprctl dispatch "$final_cmd" "$TARGET_WS,address:$focused_addr"
    fi
}

# ------------------------------------------------------------------------------
=======
>>>>>>> Stashed changes
# Mover com inserção (META+SHIFT+TAB+N)
#
# A janela focada e' INSERIDA no workspace alvo, como ao reordenar abas:
#   - Se o alvo estiver vazio, a janela simplesmente vai para la' (buracos sao
#     permitidos).
#   - Se a janela NAO for a unica do workspace de origem, o alvo e a cadeia
#     contigua de workspaces ocupados seguinte sao empurrados +1 (ate' o
#     primeiro workspace vazio do bloco do monitor).
#   - Se a janela for a UNICA da origem, a origem vira um espaco livre: a
#     cadeia entre o alvo e a origem desliza em direcao a ela. Na pratica,
#     mover para um vizinho troca os dois de lugar.
#
# DRY_RUN=1 imprime os comandos em vez de executa-los.
# ------------------------------------------------------------------------------
move_with_insert() {
    local silent="$1"
    local active_json focused_addr source_ws ws addr k chain_end final_cmd
    local -A ws_windows=()
    local -a cmds=()

    active_json=$(hyprctl -j activewindow 2>/dev/null)
    focused_addr=$(jq -r '.address // empty' <<< "$active_json" 2>/dev/null)
    source_ws=$(jq -r '.workspace.id // empty' <<< "$active_json" 2>/dev/null)

    final_cmd="movetoworkspace"
    [ "$silent" = "1" ] && final_cmd="movetoworkspacesilent"

    # Sem janela focada: comportamento padrao
    if [ -z "$focused_addr" ] || ! [[ "$source_ws" =~ ^-?[0-9]+$ ]]; then
        hyprctl dispatch moveworkspacetomonitor "$TARGET_WS" "$FOCUSED_MON" >/dev/null 2>&1
        hyprctl dispatch "$final_cmd" "$TARGET_WS"
        return
    fi

    [ "$source_ws" -eq "$TARGET_WS" ] && return

    # Mapa workspace -> janelas (exceto a focada) dentro do bloco do monitor
    while IFS=$'\t' read -r ws addr; do
        [ -n "$addr" ] && ws_windows[$ws]+="$addr "
    done < <(
        hyprctl -j clients 2>/dev/null | jq -r \
            --arg focused "$focused_addr" \
            --argjson start "$BLOCK_START" \
            --argjson end "$BLOCK_END" '
                .[]
                | select(.mapped == true and .address != $focused)
                | select(.workspace.id >= $start and .workspace.id <= $end)
                | [(.workspace.id | tostring), .address]
                | @tsv
            '
    )

    occupied() { [ -n "${ws_windows[$1]:-}" ]; }

    shift_ws() { # move todas as janelas (exceto a focada) de $1 para $2
        local from="$1" to="$2" a
        cmds+=("dispatch moveworkspacetomonitor $to $FOCUSED_MON")
        for a in ${ws_windows[$from]}; do
            cmds+=("dispatch movetoworkspacesilent $to,address:$a")
        done
    }

    local source_in_block=0 source_alone=0
    if [ "$source_ws" -ge "$BLOCK_START" ] && [ "$source_ws" -le "$BLOCK_END" ]; then
        source_in_block=1
        occupied "$source_ws" || source_alone=1
    fi

    if occupied "$TARGET_WS"; then
        if [ "$source_alone" -eq 1 ] && [ "$TARGET_WS" -gt "$source_ws" ]; then
            # Origem fica livre a' esquerda: puxa a cadeia [k..alvo] uma posicao
            # para a esquerda, parando no primeiro workspace livre (no maximo a origem).
            chain_end="$TARGET_WS"
            while [ $((chain_end - 1)) -gt "$source_ws" ] && occupied $((chain_end - 1)); do
                chain_end=$((chain_end - 1))
            done
            for (( k = chain_end; k <= TARGET_WS; k++ )); do
                shift_ws "$k" $((k - 1))
            done
        else
            # Empurra a cadeia [alvo..k] uma posicao para a direita, parando no
            # primeiro workspace livre (a origem conta como livre se ficar vazia).
            chain_end="$TARGET_WS"
            while [ $((chain_end + 1)) -le "$BLOCK_END" ] && occupied $((chain_end + 1)); do
                if [ "$source_alone" -eq 1 ] && [ $((chain_end + 1)) -eq "$source_ws" ]; then
                    break
                fi
                chain_end=$((chain_end + 1))
            done
            if [ "$chain_end" -ge "$BLOCK_END" ] && occupied "$BLOCK_END"; then
                command -v notify-send >/dev/null 2>&1 && \
                    notify-send -a "WillOS" "Workspaces" "Sem espaço livre para empurrar as janelas."
                return 1
            fi
            for (( k = chain_end; k >= TARGET_WS; k-- )); do
                shift_ws "$k" $((k + 1))
            done
        fi
    fi

    cmds+=("dispatch moveworkspacetomonitor $TARGET_WS $FOCUSED_MON")
    cmds+=("dispatch $final_cmd $TARGET_WS,address:$focused_addr")

    local batch
    batch=$(printf '%s ; ' "${cmds[@]}")
    batch="${batch% ; }"

    if [ "${DRY_RUN:-0}" = "1" ]; then
        printf '%s\n' "${cmds[@]}"
    else
        hyprctl --batch "$batch" >/dev/null
    fi
}

case "$ACTION" in
    switch)
        hyprctl dispatch moveworkspacetomonitor "$TARGET_WS" "$FOCUSED_MON" >/dev/null 2>&1
        hyprctl dispatch focusmonitor "$FOCUSED_MON" >/dev/null 2>&1
        hyprctl dispatch workspace "$TARGET_WS"
        ;;
    send)
        send_window
        ;;
    move)
        move_focused 0
        ;;
    movesilent)
        move_focused 1
        ;;
    insert)
        move_with_insert 0
        ;;
    insertsilent)
        move_with_insert 1
        ;;
    *)
        hyprctl dispatch moveworkspacetomonitor "$TARGET_WS" "$FOCUSED_MON" >/dev/null 2>&1
        hyprctl dispatch workspace "$TARGET_WS"
        ;;
esac

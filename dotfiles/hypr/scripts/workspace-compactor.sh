#!/usr/bin/env bash

# Compacta os workspaces numericos de um monitor quando o fechamento de uma
# janela deixa seu workspace vazio. Os blocos seguem a mesma convencao de
# workspace.sh: 1-10 no primeiro monitor, 11-20 no segundo, etc.

export PATH="$PATH:/run/current-system/sw/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin"

readonly WS_PER_MONITOR=10
readonly EVENT_SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
readonly LOCK_FILE="$XDG_RUNTIME_DIR/hypr-workspace-compactor.lock"

declare -A WINDOW_WORKSPACES=()

normalize_address() {
    local address="${1,,}"

    if [[ "$address" != 0x* ]]; then
        address="0x$address"
    fi

    [[ "$address" =~ ^0x[0-9a-f]+$ ]] || return 1
    REPLY="$address"
}

remember_window() {
    local address="$1"
    local workspace_id="$2"

    [[ "$workspace_id" =~ ^-?[0-9]+$ ]] || return 0
    normalize_address "$address" || return 0
    WINDOW_WORKSPACES["$REPLY"]="$workspace_id"
}

seed_window_map() {
    local address workspace_id

    while IFS=$'\t' read -r address workspace_id; do
        remember_window "$address" "$workspace_id"
    done < <(
        hyprctl -j clients 2>/dev/null \
            | jq -r '
                .[]
                | select(.mapped == true)
                | [.address, (.workspace.id | tostring)]
                | @tsv
            '
    )
}

monitor_for_workspace() {
    local workspace_id="$1"
    local monitor_index=$(( (workspace_id - 1) / WS_PER_MONITOR ))

    hyprctl -j monitors 2>/dev/null \
        | jq -r --argjson index "$monitor_index" '
            sort_by([.x, .y, .id, .name])
            | .[$index].name // empty
        '
}

compact_after_close() {
    local closed_workspace="$1"
    local block_end monitor_name clients_json
    local target_workspace source_workspace address
    local -a occupied_workspaces addresses

    (( closed_workspace > 0 )) || return 0

    block_end=$(( ((closed_workspace - 1) / WS_PER_MONITOR + 1) * WS_PER_MONITOR ))

    clients_json=$(hyprctl -j clients 2>/dev/null) || return 0
    [[ -n "$clients_json" ]] || return 0

    # O evento closewindow tambem ocorre ao fechar uma entre varias janelas.
    # So compacta se o workspace da janela fechada realmente ficou vazio.
    if jq -e --argjson workspace "$closed_workspace" \
        'any(.[]; .mapped == true and .workspace.id == $workspace)' \
        >/dev/null <<< "$clients_json"; then
        return 0
    fi

    monitor_name=$(monitor_for_workspace "$closed_workspace")
    [[ -n "$monitor_name" ]] || return 0

    mapfile -t occupied_workspaces < <(
        jq -r \
            --argjson closed "$closed_workspace" \
            --argjson end "$block_end" '
                [
                    .[]
                    | select(.mapped == true)
                    | .workspace.id
                    | select(. > $closed and . <= $end)
                ]
                | unique
                | sort
                | .[]
            ' <<< "$clients_json"
    )

    target_workspace="$closed_workspace"

    for source_workspace in "${occupied_workspaces[@]}"; do
        if (( source_workspace != target_workspace )); then
            # Vincula previamente o destino ao mesmo monitor. Isso tambem
            # preserva os blocos 1-10, 11-20, ... usados pelos atalhos META.
            hyprctl dispatch moveworkspacetomonitor \
                "$target_workspace" "$monitor_name" >/dev/null 2>&1 || true

            mapfile -t addresses < <(
                jq -r --argjson workspace "$source_workspace" '
                    .[]
                    | select(.mapped == true and .workspace.id == $workspace)
                    | .address
                ' <<< "$clients_json"
            )

            for address in "${addresses[@]}"; do
                normalize_address "$address" || continue
                address="$REPLY"

                if hyprctl dispatch movetoworkspacesilent \
                    "$target_workspace,address:$address" >/dev/null 2>&1; then
                    WINDOW_WORKSPACES["$address"]="$target_workspace"
                else
                    # Nao continue a cadeia se um workspace nao puder ser
                    # movido: o proximo destino poderia deixar de estar vazio.
                    return 0
                fi
            done
        fi

        (( target_workspace += 1 ))
    done
}

handle_event() {
    local event="$1"
    local payload address remainder workspace_id closed_workspace

    case "$event" in
        openwindow\>\>*)
            payload="${event#*>>}"
            address="${payload%%,*}"
            remainder="${payload#*,}"
            workspace_id="${remainder%%,*}"
            remember_window "$address" "$workspace_id"
            ;;

        movewindowv2\>\>*)
            payload="${event#*>>}"
            address="${payload%%,*}"
            remainder="${payload#*,}"
            workspace_id="${remainder%%,*}"
            remember_window "$address" "$workspace_id"
            ;;

        closewindow\>\>*)
            address="${event#*>>}"
            normalize_address "$address" || return 0
            address="$REPLY"
            closed_workspace="${WINDOW_WORKSPACES[$address]:-}"
            unset 'WINDOW_WORKSPACES[$address]'

            [[ "$closed_workspace" =~ ^[0-9]+$ ]] || return 0
            compact_after_close "$closed_workspace"
            ;;
    esac
}

main() {
    local event

    [[ -S "$EVENT_SOCKET" ]] || exit 0

    # Impede listeners duplicados se o script for iniciado manualmente alem do
    # exec-once do Hyprland.
    exec 9>"$LOCK_FILE"
    flock -n 9 || exit 0

    seed_window_map

    while IFS= read -r event; do
        handle_event "$event"
    done < <(socat -U - UNIX-CONNECT:"$EVENT_SOCKET")
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

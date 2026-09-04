#!/usr/bin/env bash

# Move todas as janelas de workspaces numericos para a faixa de workspaces do
# monitor em foco. Exemplo: se a faixa do monitor for 1-10, uma janela no
# workspace 31 volta para o 1, uma no 32 volta para o 2, e assim por diante.

set -u

export PATH="$PATH:/run/current-system/sw/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin"

if ! command -v hyprctl >/dev/null 2>&1; then
    echo "Erro: hyprctl nao foi encontrado." >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Erro: jq nao foi encontrado." >&2
    exit 1
fi

monitors_json=$(hyprctl -j monitors 2>/dev/null) || {
    echo "Erro: nao foi possivel consultar os monitores do Hyprland." >&2
    exit 1
}

target_monitor=$(jq -r '
    (.[] | select(.focused == true) | .name) // .[0].name // empty
' <<< "$monitors_json")

target_monitor_id=$(jq -r --arg monitor "$target_monitor" '
    .[] | select(.name == $monitor) | .id
' <<< "$monitors_json")

target_monitor_index=$(jq -r --arg monitor "$target_monitor" '
    sort_by([.x, .y, .id, .name])
    | map(.name)
    | index($monitor) // empty
' <<< "$monitors_json")

if [[ -z "$target_monitor" || ! "$target_monitor_id" =~ ^[0-9]+$ || ! "$target_monitor_index" =~ ^[0-9]+$ ]]; then
    echo "Erro: nenhum monitor ativo foi encontrado." >&2
    exit 1
fi

readonly WS_PER_MONITOR=10
target_start=$((target_monitor_index * WS_PER_MONITOR + 1))
target_end=$((target_start + WS_PER_MONITOR - 1))

clients_json=$(hyprctl -j clients 2>/dev/null) || {
    echo "Erro: nao foi possivel consultar as janelas do Hyprland." >&2
    exit 1
}

workspaces_json=$(hyprctl -j workspaces 2>/dev/null) || {
    echo "Erro: nao foi possivel consultar os workspaces do Hyprland." >&2
    exit 1
}

# Workspaces que ja pertencem a faixa correta podem apenas estar associados a
# outro monitor. Nesse caso, mover o workspace inteiro e suficiente.
mapfile -t local_workspace_ids < <(
    jq -r \
        --arg monitor "$target_monitor" \
        --argjson start "$target_start" \
        --argjson end "$target_end" '
        .[]
        | select(
            .id >= $start and .id <= $end
            and .windows > 0
            and .monitor != $monitor
        )
        | .id
    ' <<< "$workspaces_json"
)

# Janelas fora da faixa sao remapeadas pelo slot relativo: 11/21/31 viram o
# primeiro workspace da faixa alvo, 12/22/32 viram o segundo, etc.
mapfile -t rescue_rows < <(
    jq -r \
        --argjson start "$target_start" \
        --argjson end "$target_end" \
        --argjson per_monitor "$WS_PER_MONITOR" '
        .[]
        | select(
            .mapped == true
            and .workspace.id > 0
            and (.workspace.id < $start or .workspace.id > $end)
        )
        | [
            .address,
            (.workspace.id | tostring),
            (($start + ((.workspace.id - 1) % $per_monitor)) | tostring)
        ]
        | @tsv
    ' <<< "$clients_json"
)

if (( ${#local_workspace_ids[@]} == 0 && ${#rescue_rows[@]} == 0 )); then
    echo "Todas as janelas ja estao acessiveis nos workspaces $target_start-$target_end de $target_monitor."
    exit 0
fi

moved_workspaces=0
moved_windows=0
failed=0

for workspace_id in "${local_workspace_ids[@]}"; do
    if hyprctl dispatch moveworkspacetomonitor \
        "$workspace_id" "$target_monitor" >/dev/null 2>&1; then
        ((moved_workspaces += 1))
    else
        echo "Aviso: nao foi possivel mover o workspace $workspace_id." >&2
        ((failed += 1))
    fi
done

for row in "${rescue_rows[@]}"; do
    IFS=$'\t' read -r address source_workspace target_workspace <<< "$row"

    # Associa primeiro o destino ao monitor correto, inclusive quando ele ainda
    # nao existe, e depois move somente a janela para nao carregar o numero
    # antigo/inacessivel junto com ela.
    hyprctl dispatch moveworkspacetomonitor \
        "$target_workspace" "$target_monitor" >/dev/null 2>&1 || true

    if hyprctl dispatch movetoworkspacesilent \
        "$target_workspace,address:$address" >/dev/null 2>&1; then
        echo "Janela $address: workspace $source_workspace -> $target_workspace"
        ((moved_windows += 1))
    else
        echo "Aviso: nao foi possivel mover a janela $address do workspace $source_workspace." >&2
        ((failed += 1))
    fi
done

echo "$moved_windows janela(s) e $moved_workspaces workspace(s) movido(s) para $target_monitor (faixa $target_start-$target_end)."

(( failed == 0 ))

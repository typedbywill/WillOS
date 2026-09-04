#!/usr/bin/env bash

# Move todos os workspaces numericos ocupados para o monitor em foco,
# preservando as janelas em seus workspaces atuais.

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

if [[ -z "$target_monitor" ]]; then
    echo "Erro: nenhum monitor ativo foi encontrado." >&2
    exit 1
fi

workspaces_json=$(hyprctl -j workspaces 2>/dev/null) || {
    echo "Erro: nao foi possivel consultar os workspaces do Hyprland." >&2
    exit 1
}

mapfile -t workspace_ids < <(
    jq -r --arg monitor "$target_monitor" '
        .[]
        | select(.id > 0 and .windows > 0 and .monitor != $monitor)
        | .id
    ' <<< "$workspaces_json"
)

if (( ${#workspace_ids[@]} == 0 )); then
    echo "Todos os workspaces ocupados ja estao no monitor $target_monitor."
    exit 0
fi

moved=0
failed=0

for workspace_id in "${workspace_ids[@]}"; do
    if hyprctl dispatch moveworkspacetomonitor \
        "$workspace_id" "$target_monitor" >/dev/null 2>&1; then
        ((moved += 1))
    else
        echo "Aviso: nao foi possivel mover o workspace $workspace_id." >&2
        ((failed += 1))
    fi
done

echo "$moved workspace(s) movido(s) para o monitor $target_monitor."

(( failed == 0 ))

#!/usr/bin/env bash
# ==============================================================================
# 🔒 Caelestia Lock Audio Mute & Restore Utility
# Muta todas as saídas de som ao entrar no caelestia lock e restaura ao estado
# anterior no desbloqueio.
# ==============================================================================

set -euo pipefail

export PATH="$PATH:/run/current-system/sw/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin"

STATE_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/caelestia-lock-audio-state.json"

mute_all() {
    # Se o arquivo de estado já existe, a sessão já está bloqueada/mutada.
    # Evita sobrescrever o estado original com tudo mutado.
    if [ -f "$STATE_FILE" ]; then
        exit 0
    fi

    # Obtém todos os Audio/Sink ativos no PipeWire via pw-dump
    local sinks_json
    sinks_json=$(pw-dump 2>/dev/null | jq -c '[.[] | select(.info.props["media.class"] == "Audio/Sink" and .info.props["node.name"] != null) | {id: .id, name: .info.props["node.name"], mute: (.info.params.Props[0].mute // false)}]')

    if [ -z "$sinks_json" ] || [ "$sinks_json" = "[]" ]; then
        exit 0
    fi

    # Salva o estado atual no runtime dir
    echo "$sinks_json" > "$STATE_FILE"

    # Muta apenas as saídas que não estavam mutadas
    while read -r id mute; do
        if [ "$mute" = "false" ]; then
            wpctl set-mute "$id" 1 2>/dev/null || true
        fi
    done < <(echo "$sinks_json" | jq -r '.[] | "\(.id) \(.mute)"')
}

restore_all() {
    if [ ! -f "$STATE_FILE" ]; then
        exit 0
    fi

    local saved_json
    saved_json=$(cat "$STATE_FILE" 2>/dev/null || true)
    rm -f "$STATE_FILE"

    if [ -z "$saved_json" ] || [ "$saved_json" = "[]" ]; then
        exit 0
    fi

    # Obtém sinks atuais para mapear por node.name caso os IDs tenham mudado
    local current_sinks
    current_sinks=$(pw-dump 2>/dev/null | jq -c '[.[] | select(.info.props["media.class"] == "Audio/Sink" and .info.props["node.name"] != null) | {id: .id, name: .info.props["node.name"]}]' 2>/dev/null || echo "[]")

    while read -r name was_muted orig_id; do
        if [ "$was_muted" = "false" ]; then
            local curr_id
            curr_id=$(echo "$current_sinks" | jq -r --arg n "$name" '.[] | select(.name == $n) | .id' 2>/dev/null | head -n1 || true)
            if [ -n "$curr_id" ] && [ "$curr_id" != "null" ]; then
                wpctl set-mute "$curr_id" 0 2>/dev/null || true
            elif [ -n "$orig_id" ] && [ "$orig_id" != "null" ]; then
                wpctl set-mute "$orig_id" 0 2>/dev/null || true
            fi
        fi
    done < <(echo "$saved_json" | jq -r '.[] | "\(.name) \(.mute) \(.id)"')
}

case "${1:-}" in
    mute)
        mute_all
        ;;
    restore)
        restore_all
        ;;
    status)
        if [ -f "$STATE_FILE" ]; then
            echo "Bloqueado / Estado salvo em $STATE_FILE:"
            cat "$STATE_FILE" | jq .
        else
            echo "Desbloqueado (nenhum estado salvo)"
        fi
        ;;
    *)
        echo "Uso: $0 {mute|restore|status}" >&2
        exit 1
        ;;
esac

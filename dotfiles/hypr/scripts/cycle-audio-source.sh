#!/usr/bin/env bash

# ==============================================================================
# Cycle Audio Source (Microphone) Script for PipeWire / WirePlumber
# ==============================================================================

export PATH="$PATH:/run/current-system/sw/bin:$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin"

CURRENT_ID=$(wpctl inspect @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -o 'id [0-9]\+' | head -n1 | awk '{print $2}')

mapfile -t SOURCES < <(pw-dump | jq -c '[.[] | select(.info.props["media.class"] == "Audio/Source") | {id: .id, name: (.info.props["node.description"] // .info.props["node.name"])}] | sort_by(.id) | .[]')

COUNT=${#SOURCES[@]}
if [ "$COUNT" -le 1 ]; then
    exit 0
fi

CURR_IDX=-1
for i in "${!SOURCES[@]}"; do
    ID=$(echo "${SOURCES[$i]}" | jq -r '.id')
    if [ "$ID" = "$CURRENT_ID" ]; then
        CURR_IDX=$i
        break
    fi
done

NEXT_IDX=$(( (CURR_IDX + 1) % COUNT ))
NEXT_ID=$(echo "${SOURCES[$NEXT_IDX]}" | jq -r '.id')
NEXT_NAME=$(echo "${SOURCES[$NEXT_IDX]}" | jq -r '.name')

wpctl set-default "$NEXT_ID"

if command -v notify-send >/dev/null 2>&1; then
    notify-send -u low -a "Áudio" -i "audio-input-microphone" "Microfone Alterado" "$NEXT_NAME"
fi

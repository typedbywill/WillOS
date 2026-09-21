#!/usr/bin/env bash
# ==============================================================================
# TOGGLE LIQUID GLASS SHADER (ABERRAÇÃO CROMÁTICA / REFRAÇÃO ÓPTICA)
# ==============================================================================

SHADER_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/shaders/liquid_glass.frag"

# Verifica se o shader atual está ativo
IS_SET=$(hyprctl getoption decoration:screen_shader -j 2>/dev/null | jq -r '.set // false' 2>/dev/null || echo "false")
CURRENT_STR=$(hyprctl getoption decoration:screen_shader -j 2>/dev/null | jq -r '.str // empty' 2>/dev/null || echo "")

if [ "$IS_SET" = "true" ] && [ -n "$CURRENT_STR" ] && [ "$CURRENT_STR" != "[[EMPTY]]" ]; then
    # Desativa o shader
    hyprctl keyword decoration:screen_shader "" >/dev/null 2>&1
    if command -v caelestia >/dev/null 2>&1; then
        caelestia shell toaster info "Liquid Glass" "Efeito óptico desativado" "blur_off" >/dev/null 2>&1 || true
    else
        notify-send -a "Liquid Glass" "Shader óptico desativado"
    fi
else
    # Ativa o shader
    if [ -f "$SHADER_PATH" ]; then
        hyprctl keyword decoration:screen_shader "$SHADER_PATH" >/dev/null 2>&1
        if command -v caelestia >/dev/null 2>&1; then
            caelestia shell toaster success "Liquid Glass" "Aberração cromática e prisma ativados" "auto_awesome" >/dev/null 2>&1 || true
        else
            notify-send -a "Liquid Glass" "Aberração cromática ativada"
        fi
    fi
fi

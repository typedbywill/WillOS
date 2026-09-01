#!/usr/bin/env bash
# Bloqueia pelo Caelestia e, se a sessão continuar bloqueada, desliga os
# monitores após um minuto. Não altera o comportamento de inatividade normal.

caelestia shell lock lock
sleep 60

if caelestia shell lock isLocked 2>/dev/null | grep -qx 'true'; then
    hyprctl dispatch dpms off
fi

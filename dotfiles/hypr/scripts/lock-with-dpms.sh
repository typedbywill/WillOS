#!/usr/bin/env bash
# Bloqueia pelo Caelestia e muta as saídas de áudio imediatamente.
# O hypridle controla o DPMS enquanto a sessão estiver bloqueada,
# e o Caelestia restaura o áudio ao desbloquear.

caelestia-lock-audio mute 2>/dev/null || true
caelestia shell lock lock

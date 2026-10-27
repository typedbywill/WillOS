#!/usr/bin/env bash
# Bloqueia pelo Caelestia e muta as saídas de áudio imediatamente.
# O hypridle controla o DPMS enquanto a sessão estiver bloqueada,
# e o Caelestia restaura o áudio ao desbloquear.

caelestia-lock-audio mute
caelestia shell lock lock

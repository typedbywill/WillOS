#!/usr/bin/env bash
set -e

# Diretórios base
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
COLOR_SCHEMES_DIR="$DATA_DIR/color-schemes"
QTENGINE_COLORS="$CONFIG_DIR/qtengine/caelestia.colors"
KDEGLOBALS="$CONFIG_DIR/kdeglobals"

mkdir -p "$COLOR_SCHEMES_DIR"

# 1. Copia o esquema de cores dinâmico do Caelestia para os esquemas do KDE
if [ -f "$QTENGINE_COLORS" ]; then
    cp "$QTENGINE_COLORS" "$COLOR_SCHEMES_DIR/Caelestia.colors"
fi

# Determina se está no modo claro ou escuro
MODE="${SCHEME_MODE:-dark}"
if [ "$MODE" = "light" ]; then
    ICON_THEME="Papirus-Light"
else
    ICON_THEME="Papirus-Dark"
fi

# 2. Gera o kdeglobals harmonizado com as fontes, ícones e cores do Caelestia
cat << 'KDE_HEADER' > "$KDEGLOBALS"
[General]
ColorScheme=Caelestia
Name=Caelestia
font=SF Pro Display,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1
fixed=CaskaydiaCove Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1
menuFont=SF Pro Display,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1
smallestReadableFont=SF Pro Display,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1
toolBarFont=SF Pro Display,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1

[KDE]
ShowIconsInMenuItems=true
ShowIconsOnPushButtons=true
contrast=4
widgetStyle=Breeze

[Icons]
Theme=Papirus-Dark
KDE_HEADER

# Ajusta tema de ícones de acordo com o modo
sed -i "s/Theme=Papirus-Dark/Theme=$ICON_THEME/" "$KDEGLOBALS"

# Anexa a tabela completa de cores dinâmicas gerada pelo Caelestia
if [ -f "$QTENGINE_COLORS" ]; then
    cat "$QTENGINE_COLORS" >> "$KDEGLOBALS"
fi

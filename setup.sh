#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/typedbywill/myNix.git"
TARGET_DIR="${TARGET_DIR:-$HOME/nixos-hyprland-caelestia}"

echo "========================================="
echo "❄️  WillOS - Setup & Restore Script"
echo "========================================="

# 1. Clonar ou atualizar o repositório
if [ -d "$TARGET_DIR/.git" ]; then
    echo "📦 Repositório já existe em $TARGET_DIR. Atualizando..."
    git -C "$TARGET_DIR" pull --ff-only origin main 2>/dev/null || echo "ℹ️  Usando versão local existente do repositório."
else
    echo "📥 Clonando repositório de $REPO_URL para $TARGET_DIR..."
    git clone "$REPO_URL" "$TARGET_DIR"
fi

# 2. Determinação de Host
echo "🔍 Identificando perfil de máquina (multi-host)..."
ROOT_UUID=$(findmnt -no UUID / 2>/dev/null || lsblk -no UUID / 2>/dev/null || echo "")
TARGET_HOST=""

if [ -n "$ROOT_UUID" ] && grep -rnq "$ROOT_UUID" "$TARGET_DIR/hosts/casa/" 2>/dev/null; then
    TARGET_HOST="casa"
    echo "🏠 Perfil 'casa' detectado com base no UUID do disco raiz."
elif [ -n "$ROOT_UUID" ] && grep -rnq "$ROOT_UUID" "$TARGET_DIR/hosts/notegiga/" 2>/dev/null; then
    TARGET_HOST="notegiga"
    echo "💻 Perfil 'notegiga' detectado com base no UUID do disco raiz."
elif [ -d "$TARGET_DIR/hosts/$(hostname)" ]; then
    TARGET_HOST="$(hostname)"
    echo "🎯 Perfil '$TARGET_HOST' detectado pelo hostname."
else
    echo "ℹ️  Usando perfil 'casa' como padrão."
    TARGET_HOST="casa"
fi

# 3. Adicionar arquivos ao Git (necessário para o Nix Flakes enxergar)
git -C "$TARGET_DIR" add -A

# 4. Reconstruir e aplicar o sistema NixOS
echo "🚀 Aplicando configuração do NixOS ($TARGET_HOST)..."
sudo nixos-rebuild switch --flake "$TARGET_DIR#$TARGET_HOST" "$@"

echo "========================================="
echo "✨ WillOS configurado e restaurado com sucesso para o host [$TARGET_HOST]!"
echo "========================================="


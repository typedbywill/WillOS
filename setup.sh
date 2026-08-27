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

# 2. Configuração de Hardware local da máquina de destino
echo "🔍 Verificando hardware da máquina..."
if [ -f "/etc/nixos/hardware-configuration.nix" ]; then
    echo "📋 Copiando /etc/nixos/hardware-configuration.nix desta máquina..."
    cp -f /etc/nixos/hardware-configuration.nix "$TARGET_DIR/hardware-configuration.nix"
elif [ ! -f "$TARGET_DIR/hardware-configuration.nix" ]; then
    echo "⚙️  Gerando hardware-configuration.nix local..."
    sudo nixos-generate-config --show-hardware-config > "$TARGET_DIR/hardware-configuration.nix"
else
    echo "ℹ️  Mantendo hardware-configuration.nix já presente."
fi

# Detecta GPU e define o perfil se ainda não estiver configurado
if ! grep -q "myHardware.gpu.type" "$TARGET_DIR/hardware-configuration.nix"; then
    echo "🔎 Detectando GPU para definir perfil de hardware..."
    if lspci 2>/dev/null | grep -iq "nvidia"; then
        echo "🎮 GPU NVIDIA detectada. Ativando perfil Nvidia..."
        sed -i 's/}$/  myHardware.gpu.type = lib.mkDefault "nvidia";\n}/' "$TARGET_DIR/hardware-configuration.nix"
    elif lspci 2>/dev/null | grep -iq "amd"; then
        echo "🎮 GPU AMD detectada. Ativando perfil AMD..."
        sed -i 's/}$/  myHardware.gpu.type = lib.mkDefault "amd";\n}/' "$TARGET_DIR/hardware-configuration.nix"
    else
        echo "💻 GPU Intel/Genérica detectada. Ativando perfil Intel..."
        sed -i 's/}$/  myHardware.gpu.type = lib.mkDefault "intel";\n}/' "$TARGET_DIR/hardware-configuration.nix"
    fi
fi

# 3. Adicionar arquivos ao Git (necessário para o Nix Flakes enxergar)
git -C "$TARGET_DIR" add -A

# 4. Reconstruir e aplicar o sistema NixOS
echo "🚀 Aplicando configuração do NixOS..."
sudo nixos-rebuild switch --flake "$TARGET_DIR#nixos" "$@"

echo "========================================="
echo "✨ WillOS configurado e restaurado com sucesso!"
echo "========================================="

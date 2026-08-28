#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/typedbywill/myNix.git"
TARGET_DIR="${TARGET_DIR:-$HOME/nixos-hyprland-caelestia}"

echo "========================================="
echo "❄️  WillOS - Universal Setup & Installer"
echo "========================================="

# Helper para executar comandos git mesmo se o git não estiver no PATH inicial
run_git() {
    if command -v git >/dev/null 2>&1; then
        git "$@"
    else
        nix-shell -p git --run "git $(printf '%q ' "$@")"
    fi
}

# 1. Clonar ou atualizar o repositório
if [ -d "$TARGET_DIR/.git" ]; then
    echo "📦 Repositório já existe em $TARGET_DIR. Atualizando..."
    run_git -C "$TARGET_DIR" pull --ff-only origin main 2>/dev/null || echo "ℹ️  Usando versão local existente do repositório."
else
    echo "📥 Clonando repositório de $REPO_URL para $TARGET_DIR..."
    run_git clone "$REPO_URL" "$TARGET_DIR"
fi

# 2. Configurar o hardware-configuration.nix local
if [ ! -f "$TARGET_DIR/hardware-configuration.nix" ]; then
    if [ -f "/etc/nixos/hardware-configuration.nix" ]; then
        echo "📋 Copiando hardware-configuration.nix existente de /etc/nixos/..."
        cp "/etc/nixos/hardware-configuration.nix" "$TARGET_DIR/hardware-configuration.nix"
    else
        echo "⚙️  Gerando hardware-configuration.nix para esta máquina..."
        if command -v nixos-generate-config >/dev/null 2>&1; then
            nixos-generate-config --show-hardware-config > "$TARGET_DIR/hardware-configuration.nix"
        else
            sudo nixos-generate-config --show-hardware-config > "$TARGET_DIR/hardware-configuration.nix"
        fi
    fi
else
    echo "✔ hardware-configuration.nix local já configurado."
fi

# 3. Gerar local-config.nix (se ainda não existir) com detecção inteligente de GPU e Hostname
if [ ! -f "$TARGET_DIR/local-config.nix" ]; then
    echo "🔍 Detectando hardware local (GPU e Hostname)..."
    
    DETECTED_HN=$(hostname 2>/dev/null || echo "")
    if [ -z "$DETECTED_HN" ] || [ "$DETECTED_HN" = "nixos" ]; then
        DETECTED_HN="willos"
    fi

    DETECTED_GPU="none"
    if lspci 2>/dev/null | grep -iq "nvidia"; then
        DETECTED_GPU="nvidia"
    elif lspci 2>/dev/null | grep -iE "vga|3d" | grep -iq "intel"; then
        DETECTED_GPU="intel"
    elif lspci 2>/dev/null | grep -iE "vga|3d" | grep -iq "amd\|radeon"; then
        DETECTED_GPU="amd"
    fi

    echo "💡 Hardware detectado: Hostname='$DETECTED_HN', GPU='$DETECTED_GPU'"
    cat <<EOF > "$TARGET_DIR/local-config.nix"
# ==============================================================================
# 🛠️ WillOS - Configuração Local da Máquina
# Gerado automaticamente pelo setup.sh
# ==============================================================================
{ lib, ... }:

{
  networking.hostName = "${DETECTED_HN}";
  myHardware.gpu.type = "${DETECTED_GPU}";
}
EOF
    echo "✔ local-config.nix criado com sucesso."
else
    echo "✔ local-config.nix já existente (mantendo preferências locais)."
fi

# 4. Assegurar que arquivos locais fiquem fora do Git
run_git -C "$TARGET_DIR" reset HEAD hardware-configuration.nix local-config.nix 2>/dev/null || true

# 5. Reconstruir e aplicar o sistema NixOS
echo "🚀 Aplicando configuração universal do WillOS..."
sudo FLAKE_DIR="$TARGET_DIR" nixos-rebuild switch --impure --flake "$TARGET_DIR#willos" "$@"

echo "========================================="
echo "✨ WillOS configurado e ativado com sucesso!"
echo "========================================="

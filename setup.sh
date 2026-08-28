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
TARGET_HOST=""
CURRENT_HN=$(hostname 2>/dev/null || echo "")

if [ -n "$CURRENT_HN" ] && [ "$CURRENT_HN" != "nixos" ] && [ -d "$TARGET_DIR/hosts/$CURRENT_HN" ]; then
    TARGET_HOST="$CURRENT_HN"
    echo "🎯 Perfil '$TARGET_HOST' detectado diretamente pelo hostname."
else
    # Varredura de todos os UUIDs presentes no hardware
    SYSTEM_UUIDS=()
    if [ -d "/dev/disk/by-uuid" ]; then
        while IFS= read -r u; do
            [ -n "$u" ] && SYSTEM_UUIDS+=("$u")
        done < <(ls -1 /dev/disk/by-uuid/ 2>/dev/null || true)
    fi
    while IFS= read -r u; do
        [ -n "$u" ] && SYSTEM_UUIDS+=("$u")
    done < <(lsblk -rno UUID 2>/dev/null || true)

    BEST_SCORE=0
    for h_dir in "$TARGET_DIR/hosts"/*; do
        [ ! -d "$h_dir" ] && continue
        h_name="$(basename "$h_dir")"
        hw_file="$h_dir/hardware-configuration.nix"
        [ ! -f "$hw_file" ] && continue

        SCORE=0
        for u in "${SYSTEM_UUIDS[@]}"; do
            if grep -Fq "$u" "$hw_file" 2>/dev/null; then
                ((SCORE += 15))
            fi
        done

        if grep -Eq "hardware\.cpu\.intel|kvm-intel" "$hw_file" 2>/dev/null && grep -iq "intel" /proc/cpuinfo 2>/dev/null; then
            ((SCORE += 3))
        elif grep -Eq "hardware\.cpu\.amd|kvm-amd" "$hw_file" 2>/dev/null && grep -iq "amd" /proc/cpuinfo 2>/dev/null; then
            ((SCORE += 3))
        fi

        if [ "$SCORE" -gt "$BEST_SCORE" ]; then
            BEST_SCORE=$SCORE
            TARGET_HOST="$h_name"
        fi
    done

    if [ -n "$TARGET_HOST" ] && [ "$BEST_SCORE" -gt 0 ]; then
        echo "💻 Perfil '$TARGET_HOST' detectado com base na compatibilidade de hardware/discos (score: $BEST_SCORE)."
    else
        echo "ℹ️  Usando perfil 'casa' como padrão."
        TARGET_HOST="casa"
    fi
fi


# 3. Adicionar arquivos ao Git (necessário para o Nix Flakes enxergar)
git -C "$TARGET_DIR" add -A

# 4. Reconstruir e aplicar o sistema NixOS
echo "🚀 Aplicando configuração do NixOS ($TARGET_HOST)..."
sudo nixos-rebuild switch --flake "$TARGET_DIR#$TARGET_HOST" "$@"

echo "========================================="
echo "✨ WillOS configurado e restaurado com sucesso para o host [$TARGET_HOST]!"
echo "========================================="


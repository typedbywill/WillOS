#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Se git estiver disponível, adiciona arquivos novos/modificados para o Flake enxergar
if command -v git >/dev/null 2>&1; then
    git -C "$repo_dir" add -A
fi

echo "🚀 Reconstruindo e ativando a configuração do NixOS + Home Manager..."
sudo nixos-rebuild switch --flake "$repo_dir#nixos"

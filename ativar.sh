#!/usr/bin/env bash
set -euo pipefail

origem="/home/william/nixos-hyprland-caelestia"
destino="/etc/nixos"
data="$(date +%Y%m%d-%H%M%S)"

sudo install -d -m 0755 "$destino/backups/$data"
sudo cp -a "$destino/configuration.nix" "$destino/backups/$data/configuration.nix"
sudo install -m 0644 "$origem/flake.nix" "$destino/flake.nix"
sudo install -m 0644 "$origem/flake.lock" "$destino/flake.lock"
sudo install -m 0644 "$origem/configuration.nix" "$destino/configuration.nix"
sudo install -m 0644 "$origem/hardware-configuration.nix" "$destino/hardware-configuration.nix"

# Caelestia obtém o Quickshell a partir de um repositório Git. Uma instalação
# NixOS mínima ainda não inclui Git, portanto disponibilizamos o pacote apenas
# durante esta primeira reconstrução.
git_path="$(NIX_CONFIG='experimental-features = nix-command flakes' nix build --no-link --print-out-paths github:NixOS/nixpkgs/nixos-unstable#git)"
sudo env PATH="$git_path/bin:$PATH" NIX_CONFIG='experimental-features = nix-command flakes' nixos-rebuild switch --flake "$destino#nixos"

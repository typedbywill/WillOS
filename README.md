# ❄️ NixOS Hyprland & Caelestia Config

Configuração declarativa e reproduzível do NixOS com Flakes e Home Manager.

## 📁 Estrutura do Repositório

```
.
├── setup.sh                   # Script de instalação/restauração rápida em qualquer máquina
├── flake.nix                  # Definição do Flake e inputs (nixpkgs, home-manager, etc.)
├── flake.lock                 # Versões travadas dos pacotes e módulos
├── configuration.nix          # Configuração do sistema (serviços, drivers, boot, etc.)
├── hardware-configuration.nix # Mapeamento de hardware e discos da máquina
├── home.nix                   # Home Manager (pacotes de usuário, temas, dotfiles)
└── dotfiles/                  # Arquivos de configuração dos aplicativos
    ├── hypr/
    │   └── hyprland.conf      # Configuração do Hyprland
    ├── kitty/
    │   └── kitty.conf         # Configuração do emulador de terminal Kitty
    ├── caelestia/
    │   └── shell.json         # Configuração da barra/shell Caelestia
    ├── fish/
    │   └── config.fish        # Configuração e aliases do shell Fish
    ├── fastfetch/
    │   └── config.jsonc       # Informações do sistema Fastfetch
    ├── fuzzel/
    │   └── fuzzel.ini         # Launcher de aplicativos
    ├── cava/
    │   └── config             # Visualizador de áudio
    └── htop/
        └── htoprc             # Gerenciador de processos
```

## 🚀 Como Aplicar Alterações (Nesta Máquina)

Após editar qualquer arquivo de configuração ou dotfile, basta rodar no terminal:
```bash
rebuild
```

*(Ou o comando completo: `sudo nixos-rebuild switch --flake /home/william/nixos-hyprland-caelestia#nixos`)*

## 🌐 Como Restaurar em Outra Máquina NixOS (Apenas Terminal)

Em qualquer máquina NixOS conectada à internet, basta rodar um único comando no terminal (sem necessidade de chaves SSH ou permissão prévia):

```bash
bash <(curl -sL https://raw.githubusercontent.com/typedbywill/myNix/main/setup.sh)
```

O script cuidará de:
1. Clonar o repositório via HTTPS público para `~/nixos-hyprland-caelestia`.
2. Preservar ou gerar o `hardware-configuration.nix` específico da máquina de destino.
3. Executar o `nixos-rebuild switch` completo.


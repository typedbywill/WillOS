# ❄️ NixOS Hyprland & Caelestia Config

Configuração declarativa e reproduzível do NixOS com Flakes e Home Manager.

## 📁 Estrutura do Repositório

```
.
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

## 🚀 Como Aplicar Alterações

Após editar qualquer arquivo de configuração ou dotfile, basta rodar no terminal:
```bash
rebuild
```

*(Ou o comando completo: `sudo nixos-rebuild switch --flake /home/william/nixos-hyprland-caelestia#nixos`)*

## 🐙 Como Subir para o GitHub

1. Crie um repositório no seu GitHub (ex: `nixos-config`).
2. Adicione o repositório remoto e envie:
   ```bash
   git remote add origin git@github.com:seu-usuario/nixos-config.git
   git branch -M main
   git push -u origin main
   ```

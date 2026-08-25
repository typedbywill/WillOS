# ❄️ NixOS Hyprland & Caelestia Config (Base Pública)

Configuração declarativa, moderna e 100% reproduzível do NixOS com Flakes e Home Manager.

Esta é a **Camada Base Pública** do sistema. Ela foi projetada para ser **completamente autossuficiente e genérica**, permitindo instalar um desktop visualmente completo com Hyprland, Caelestia Shell, fontes e temas em qualquer máquina nova sem depender de chaves SSH, credenciais ou dados sensíveis.

---

## 🏗️ Arquitetura em Duas Camadas

1. **Camada 1 (Este Repositório - Público)**: Instalação do sistema operacional, drivers, Wayland/Hyprland, Caelestia, navegadores, terminal, fontes e tema visual padrão.
2. **Camada 2 ([Repositório Privado](https://github.com/typedbywill/nixos-private))**: Injeta wallpapers pessoais, credenciais/tokens (Cloudflare Tunnel), configurações e pareamentos declarativos do Syncthing.

---

## 📁 Estrutura do Repositório

```text
.
├── setup.sh                   # Script de instalação/restauração zero-auth em qualquer máquina
├── flake.nix                  # Flake principal do sistema (inputs, módulos e outputs)
├── flake.lock                 # Travamento de versões dos pacotes e flakes
├── configuration.nix          # Configuração do sistema (serviços, drivers NVIDIA, áudio, boot)
├── hardware-configuration.nix # Mapeamento de hardware e discos da máquina local
├── home.nix                   # Home Manager (pacotes de usuário, temas GTK/Qt, dotfiles)
├── wallpapers/                # Papéis de parede padrão do sistema
│   └── default.jpg
└── dotfiles/                  # Arquivos de configuração dos utilitários
    ├── hypr/
    │   ├── hyprland.conf      # Configuração do compositor Hyprland
    │   ├── scheme/            # Esquema inicial de cores do tema
    │   └── scripts/           # Scripts de display virtual automático / Sunshine
    ├── kitty/                 # Emulador de terminal Kitty
    ├── caelestia/             # Shell Caelestia, CLI e scripts de integração com KDE
    ├── fish/                  # Shell Fish e aliases
    ├── fastfetch/             # Informações do sistema Fastfetch
    ├── fuzzel/                # Launcher de aplicativos
    ├── cava/                  # Visualizador de áudio no terminal
    ├── dolphin/               # Configurações do gerenciador de arquivos Dolphin
    └── htop/                  # Gerenciador de processos
```

---

## 🌐 Como Instalar em Qualquer Máquina Nova (Zero Auth)

Em qualquer instalação nova do NixOS conectada à internet, basta executar um único comando no terminal:

```bash
bash <(curl -sL https://raw.githubusercontent.com/typedbywill/myNix/main/setup.sh)
```

O script realizará:
1. Clone do repositório via HTTPS público para `~/nixos-hyprland-caelestia`.
2. Preservação/geração automática do `hardware-configuration.nix` da máquina de destino.
3. Execução do `nixos-rebuild switch` completo.

---

## 🚀 Como Aplicar Alterações Locais

Após editar qualquer arquivo de configuração ou dotfile neste repositório:

```bash
rebuild
```

*(Ou o comando completo: `sudo nixos-rebuild switch --flake /home/william/nixos-hyprland-caelestia#nixos`)*

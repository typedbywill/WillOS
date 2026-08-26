# ❄️ NixOS Hyprland & Caelestia Config (Base Pública)

Configuração declarativa, moderna e 100% reproduzível do NixOS com Flakes e Home Manager.

Esta é a **Camada Base Pública** do sistema. Ela foi projetada para ser **completamente autossuficiente e genérica**, permitindo instalar um desktop visualmente completo com Hyprland, Caelestia Shell, fontes e temas em qualquer máquina nova sem depender de chaves SSH, credenciais ou dados sensíveis.

---

## ⚡ Princípio Fundamental: Separação entre Configuração vs. Hardware

> [!IMPORTANT]
> **A sincronização é apenas para Configurações e Dotfiles. Hardware, Infraestrutura e Partições NUNCA devem ser acoplados rigidamente entre máquinas.**

- **O que É sincronizado (Configurações Universais)**:
  - Ambiente gráfico (Hyprland, Caelestia Shell, Waybar, temas visuais, esquemas de cores e fontes).
  - Shell Fish, aliases, atalhos de teclado e utilitários do terminal.
  - Programas, associações de arquivos e preferências do usuário (Home Manager).
  - Scripts de comportamento do desktop (workspaces multi-telas, display virtual, Sunshine).

- **O que NÃO deve ser sincronizado de forma estática (Hardware & Infraestrutura)**:
  - **Discos, UUIDs e Criptografia (LUKS)**: Cada máquina física possui sua própria tabela de partições e identificadores únicos.
  - **Processador e Módulos de Kernel**: Microcódigo Intel vs. AMD e módulos de virtualização (`kvm-intel` vs. `kvm-amd`).
  - **Drivers de GPU**: Gerenciados dinamicamente via módulo modular [`modules/gpu.nix`](./modules/gpu.nix) (`intel`, `nvidia`, `hybrid-intel-nvidia` ou `amd`).

📌 **Como o sistema resolve isso?**
O repositório adota uma **arquitetura multi-host** em [`hosts/`](./hosts) (`hosts/casa`, `hosts/notegiga`, etc.) e preserva o `hardware-configuration.nix` gerado localmente em novas instalações através do `setup.sh`.

---

## 🏗️ Arquitetura em Duas Camadas

1. **Camada 1 (Este Repositório - Público)**: Instalação do sistema operacional, drivers, Wayland/Hyprland, Caelestia, navegadores, terminal, fontes e tema visual padrão.
2. **Camada 2 ([Repositório Privado](https://github.com/typedbywill/nixos-private))**: Injeta wallpapers pessoais, credenciais/tokens (Cloudflare Tunnel), configurações e pareamentos declarativos do Syncthing.

---

## 📁 Estrutura do Repositório

```text
.
├── setup.sh                   # Script de instalação/restauração zero-auth em qualquer máquina
├── flake.nix                  # Flake principal do sistema com suporte multi-host
├── flake.lock                 # Travamento de versões dos pacotes e flakes
├── configuration.nix          # Configuração compartilhada do sistema (serviços, áudio, boot, etc.)
├── hardware-configuration.nix # Mapeamento de hardware genérico/fallback
├── home.nix                   # Home Manager (pacotes de usuário, temas GTK/Qt, dotfiles)
├── hosts/                     # Configurações isoladas de hardware por máquina
│   ├── casa/                  # Desktop AMD + GPU NVIDIA
│   └── notegiga/                # Notebook Intel + GPU Intel + LUKS
├── modules/                   # Módulos opcionais do sistema
│   └── gpu.nix                # Gerenciador dinâmico de drivers gráficos (Intel / AMD / Nvidia)
├── wallpapers/                # Papéis de parede padrão do sistema
│   └── default.jpg
└── dotfiles/                  # Arquivos de configuração dos utilitários
    ├── hypr/
    │   ├── hyprland.conf      # Configuração do compositor Hyprland
    │   ├── scheme/            # Esquema de cores e tema
    │   └── scripts/           # Scripts de display virtual automático e workspaces por monitor
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
2. Preservação/geração automática do `hardware-configuration.nix` da máquina de destino com auto-detecção de GPU.
3. Execução do `nixos-rebuild switch` completo.

---

## 🚀 Como Aplicar Alterações Locais

Após editar qualquer arquivo de configuração ou dotfile neste repositório:

```bash
rebuild
```

*(Ou o comando completo: `sudo nixos-rebuild switch --flake /home/william/nixos-hyprland-caelestia`)*

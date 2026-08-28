# ❄️ WillOS (Base Pública)

Configuração declarativa, moderna e 100% reproduzível do **WillOS** (NixOS com Flakes, Hyprland, Caelestia Shell e Home Manager).

Esta é a **Camada Base Pública** do sistema. Ela foi projetada como uma **plataforma universal plug-and-play**, permitindo instalar um desktop visualmente completo com Hyprland, Caelestia Shell, fontes, atalhos e ferramentas em qualquer computador sem acoplamento de hardware.

---

## ⚡ Princípio Fundamental: Separação entre Sistema vs. Hardware

> [!IMPORTANT]
> **O WillOS compartilha configurações, ambientes de trabalho e dotfiles. O hardware (discos, UUIDs e GPU) é desacoplado e configurado localmente em cada máquina.**

- **O que É sincronizado no Git (Configurações Universais)**:
  - Ambiente gráfico (Hyprland, Caelestia Shell, Waybar, temas visuais, esquemas de cores e fontes).
  - Shell Fish, aliases, autocompletes, atalhos de teclado e utilitários do terminal.
  - Programas, associações de arquivos e preferências do usuário (Home Manager).
  - Scripts de comportamento do desktop (workspaces multi-telas, display virtual, Sunshine).
  - Módulos do sistema (GPU modular: `intel`, `nvidia`, `amd`, `hybrid-intel-nvidia`).

- **O que É mantido LOCALMENTE fora do Git**:
  - `hardware-configuration.nix` *(ignorado no Git)*: Gerado pelo `nixos-generate-config` na própria máquina com os UUIDs das partições e módulos de boot daquela placa-mãe.
  - `local-config.nix` *(ignorado no Git)*: Arquivo simples para definir o Hostname e o Driver de GPU da máquina atual (veja `local-config.example.nix`).

---

## 🏗️ Arquitetura em Duas Camadas

1. **Camada 1 (Este Repositório - Público)**: Instalação do sistema operacional, drivers, Wayland/Hyprland, Caelestia, navegadores, terminal, fontes e tema visual padrão.
2. **Camada 2 ([Repositório Privado](https://github.com/typedbywill/nixos-private))**: Injeta wallpapers pessoais, credenciais/tokens (Cloudflare Tunnel), configurações e pareamentos declarativos do Syncthing.

---

## 📁 Estrutura do Repositório

```text
.
├── setup.sh                   # Script instalador universal e autônomo para qualquer máquina
├── flake.nix                  # Flake principal universal (nixosConfigurations.willos)
├── flake.lock                 # Travamento de versões dos pacotes e flakes
├── configuration.nix          # Configuração compartilhada do sistema (serviços, áudio, boot, etc.)
├── home.nix                   # Home Manager (pacotes de usuário, temas GTK/Qt, dotfiles)
├── local-config.example.nix   # Template documentado de configurações locais de máquina
│
├── hardware-configuration.nix # [Local / .gitignore] Gerado automaticamente no hardware local
├── local-config.nix           # [Local / .gitignore] Configurações locais (GPU, Hostname)
│
├── modules/                   # Módulos opcionais do sistema
│   ├── gpu.nix                # Gerenciador dinâmico de drivers gráficos (Intel / AMD / Nvidia)
│   └── spotify-inactivity-watcher.nix # Watcher de inatividade do Spotify
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

### Opção 1: Script Automatizado (`setup.sh`) *(Recomendado)*

O instalador clona o repositório, gera o `hardware-configuration.nix` da máquina, auto-detecta a GPU (Nvidia, Intel ou AMD) e ativa o sistema:

```bash
bash <(curl -sL https://raw.githubusercontent.com/typedbywill/WillOS/main/scripts/setup.sh)
```

> [!NOTE]
> O `setup.sh` possui fallback automático via `nix-shell` e funcionará perfeitamente mesmo se a máquina ainda não tiver o `git` instalado.

---

### Opção 2: Instalação Manual

```bash
git clone https://github.com/typedbywill/WillOS.git ~/nixos-hyprland-caelestia
cd ~/nixos-hyprland-caelestia

# Copiar ou gerar o hardware-configuration da máquina:
cp /etc/nixos/hardware-configuration.nix ./hardware-configuration.nix

# Criar a configuração local com GPU e Hostname:
cp local-config.example.nix local-config.nix

# Aplicar o sistema:
sudo nixos-rebuild switch --flake .#willos
```

---

## 🚀 Como Aplicar Alterações Locais

Após editar qualquer arquivo de configuração ou dotfile neste repositório:

```bash
rebuild
```

### 🛡️ Recursos de Segurança & Auditoria Integrados:
- **Auditoria de Hardware & Discos**: Antes de executar o rebuild, o script inspeciona e valida se as partições e discos mapeados no hardware local estão ativos.
- **Detecção e Preservação Local**: Seus arquivos `local-config.nix` e `hardware-configuration.nix` são preservados e isolados do Git.
- **Confirmação Interativa**: Exibe um resumo completo da geração atual, discos, GPU e alterações antes de aplicar.

### ⚙️ Opções Úteis do Comando:
- `rebuild --info`: Apenas exibe o painel de auditoria de hardware e discos sem aplicar nada.
- `rebuild -u` / `--upgrade`: Atualiza todos os inputs do Flake (`nix flake update`) antes do rebuild.
- `rebuild -y` / `--yes`: Pula a confirmação interativa para automações.
- `rebuild --fast`: Pula a sincronização remota do Git (modo offline/rápido).
- `rebuild --boot`: Adiciona a nova geração ao bootloader sem ativar imediatamente.
- `rebuild --test`: Testa a configuração temporariamente sem alterar o bootloader.

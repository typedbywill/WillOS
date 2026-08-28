# ❄️ WillOS (Base Pública)

Configuração declarativa, moderna e 100% reproduzível do **WillOS** (NixOS com Flakes, Hyprland, Caelestia Shell e Home Manager).

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

Você pode instalar o **WillOS** diretamente sem precisar de chaves SSH ou de autenticação.

### Opção 1: Direto via Flake Remoto *(Recomendado — Não requer Git)*

O próprio Nix baixa e constrói tudo a partir do repositório remoto:

* **Em um sistema NixOS em execução:**
  ```bash
  # Para o perfil Notebook:
  sudo nixos-rebuild switch --flake github:typedbywill/myNix#notegiga

  # Para o perfil Desktop:
  sudo nixos-rebuild switch --flake github:typedbywill/myNix#casa
  ```

* **Durante uma instalação limpa via pendrive/Live ISO (`nixos-install`):**
  ```bash
  sudo nixos-install --flake github:typedbywill/myNix#notegiga
  ```

---

### Opção 2: Script Automatizado (`setup.sh`)

Se preferir que o script clone o repositório localmente em `~/nixos-hyprland-caelestia`, detecte automaticamente o hardware/perfil e aplique o sistema:

```bash
bash <(curl -sL https://raw.githubusercontent.com/typedbywill/myNix/main/setup.sh)
```

> [!NOTE]
> O `setup.sh` possui fallback automático via `nix-shell` e funcionará perfeitamente mesmo se a máquina ainda não tiver o `git` instalado.

---

## 🚀 Como Aplicar Alterações Locais

Após editar qualquer arquivo de configuração ou dotfile neste repositório:

```bash
rebuild
```

### 🛡️ Recursos de Segurança & Auditoria Integrados:
- **Auditoria de Hardware & Discos**: Antes de executar qualquer alteração, o script inspeciona e valida se as partições e UUIDs configuradas no perfil (`/`, `/boot`, LUKS, Swap) realmente existem e estão ativas no hardware físico atual.
- **Detecção Inteligente Multi-Host**: Identifica automaticamente se a máquina é `notegiga`, `casa`, etc., através da varredura de hardware e UUIDs.
- **Confirmação Interativa**: Exibe um resumo completo do que será atualizado e permite confirmar (`S`), cancelar (`n`) ou trocar de perfil interativamente (`t`).

### ⚙️ Opções Úteis do Comando:
- `rebuild --info`: Apenas exibe o painel de auditoria de hardware, perfil e discos sem aplicar nada.
- `rebuild --host <nome>` / `-H <nome>`: Força um perfil específico (ex: `rebuild --host notegiga`).
- `rebuild -u` / `--upgrade`: Atualiza todos os inputs do Flake (`nix flake update`) antes do rebuild.
- `rebuild -y` / `--yes`: Pula a confirmação interativa para automações.
- `rebuild --fast`: Pula a sincronização remota do Git (modo offline).
- `rebuild --boot`: Adiciona a nova geração ao bootloader sem chavear imediatamente.


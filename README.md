# ❄️ WillOS (Base Pública)

Configuração declarativa, moderna e 100% reproduzível do **WillOS** (NixOS com Flakes, Hyprland, Caelestia Shell e Home Manager).

Esta é a **Camada Base Pública** do sistema. Ela foi projetada como uma **plataforma universal plug-and-play**, permitindo instalar um desktop visualmente completo com Hyprland, Caelestia Shell, fontes, atalhos e ferramentas em qualquer computador sem acoplamento de hardware.

---

## ⚡ Regra Fundamental: Base Única + Configuração Local

> [!IMPORTANT]
> **O WillOS não possui perfis por máquina.** Não crie alvos como `casa`, `notebook` ou nomes de computadores. Existe somente `nixosConfigurations.willos`; hardware, hostname e qualquer personalização da máquina entram em arquivos locais ignorados pelo Git.

- **O que É sincronizado no Git (Configurações Universais)**:
  - Ambiente gráfico (Hyprland, Caelestia Shell, Waybar, temas visuais, esquemas de cores e fontes).
  - Shell Fish, aliases, autocompletes, atalhos de teclado e utilitários do terminal.
  - Programas, associações de arquivos e preferências do usuário (Home Manager).
  - Scripts de comportamento do desktop (workspaces multi-telas, display virtual, Sunshine).
  - Módulos do sistema (GPU modular: `intel`, `nvidia`, `amd`, `hybrid-intel-nvidia`).

- **O que fica LOCALMENTE e nunca é sincronizado pelo Git**:
  - `hardware-configuration.nix` *(ignorado no Git)*: Gerado pelo `nixos-generate-config` na própria máquina com os UUIDs das partições e módulos de boot daquela placa-mãe.
  - `local-config.nix` *(ignorado no Git)*: Hostname, GPU e demais opções particulares desta instalação (veja `local-config.example.nix`).

As regras são intencionais:

1. Não existem diretórios, módulos ou outputs por computador.
2. O template público contém apenas valores genéricos; nunca edite o template com dados reais.
3. O `rebuild` usa sempre `.#willos` e recusa `--host` e `--profile`.
4. O `rebuild` é interrompido se os dois arquivos locais deixarem de estar ignorados ou aparecerem no índice do Git.

> [!WARNING]
> Ignorar um arquivo no Git impede a sincronização, mas não transforma segredos em opções Nix seguras: valores usados durante o build podem aparecer na Nix Store. Senhas, tokens e chaves devem ficar fora deste repositório e fora das expressões Nix, em um gerenciador de segredos apropriado.

---

## 📁 Estrutura do Repositório

```text
.
├── setup.sh                   # Script instalador universal e autônomo para qualquer máquina
├── flake.nix                  # Único alvo público: nixosConfigurations.willos
├── flake.lock                 # Travamento de versões dos pacotes e flakes
├── configuration.nix          # Configuração compartilhada do sistema (serviços, áudio, boot, etc.)
├── home.nix                   # Home Manager (pacotes de usuário, temas GTK/Qt, dotfiles)
├── local-config.example.nix   # Template público genérico; não recebe valores reais
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
git clone https://github.com/typedbywill/WillOS.git ~/WillOS
cd ~/WillOS

# Copiar ou gerar o hardware-configuration da máquina:
cp /etc/nixos/hardware-configuration.nix ./hardware-configuration.nix

# Criar a configuração exclusivamente local com GPU e hostname:
cp local-config.example.nix local-config.nix

# Editar somente a cópia ignorada:
$EDITOR local-config.nix

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
- **Barreira contra vazamento**: `local-config.nix` e `hardware-configuration.nix` precisam estar ignorados e não rastreados; caso contrário, o rebuild acusa o problema e para.
- **Alvo único**: Toda máquina aplica a mesma base com `.#willos`; diferenças são lidas somente dos arquivos locais.
- **Confirmação Interativa**: Exibe um resumo completo da geração atual, discos, GPU e alterações antes de aplicar.

Para conferir manualmente a separação:

```bash
git check-ignore -v hardware-configuration.nix local-config.nix
git ls-files --error-unmatch hardware-configuration.nix local-config.nix
```

O primeiro comando deve listar as regras do `.gitignore`; o segundo deve falhar, confirmando que nenhum dos arquivos está rastreado.

### ⚙️ Opções Úteis do Comando:
- `rebuild --info`: Apenas exibe o painel de auditoria de hardware e discos sem aplicar nada.
- `rebuild -u` / `--upgrade`: Atualiza todos os inputs do Flake (`nix flake update`) antes do rebuild.
- `rebuild -y` / `--yes`: Pula a confirmação interativa para automações.
- `rebuild --fast`: Pula a sincronização remota do Git (modo offline/rápido).
- `rebuild --boot`: Adiciona a nova geração ao bootloader sem ativar imediatamente.
- `rebuild --test`: Testa a configuração temporariamente sem alterar o bootloader.

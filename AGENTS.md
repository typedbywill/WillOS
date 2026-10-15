# Regras de Arquitetura & Contribuição para Agentes e Desenvolvedores (WillOS)

Este repositório é a **Camada Base Pública Universal** do WillOS.
Ele é compartilhado e sincronizado entre múltiplos computadores (incluindo laptops com Intel integrada, desktops com GPUs NVIDIA/AMD dedicadas e setups híbridos).

---

## ⛔ REGRA FUNDAMENTAL: NUNCA COLOQUE CONFIGURAÇÕES LOCAIS NA BASE PÚBLICA

Nenhuma configuração particular de hardware, identidade pessoal, caminhos locais ou preferências específicas de máquina deve ser colocada em arquivos rastreados pelo Git (`dotfiles/`, `configuration.nix`, `home.nix`, `modules/`, etc.).

### 1. Configurações de GPU e Drivers de Vídeo
- **PROIBIDO**: Definir `AQ_DRM_DEVICES`, caminhos fixos de `/dev/dri/*` ou forçar drivers de vídeo em:
  - `dotfiles/hypr/hyprland.conf`
  - `home.nix` (ex: `xdg.configFile."uwsm/env"`)
  - `configuration.nix`
- **COMO FAZER**:
  - Toda máquina declara seu tipo de GPU em `local-config.nix` (arquivo ignorado pelo Git):
    ```nix
    myHardware.gpu.type = "intel"; # ou "nvidia", "hybrid-intel-nvidia", "amd"
    ```
  - O módulo [`modules/gpu.nix`](modules/gpu.nix) gerencia de forma dinâmica e automática a injeção condicional de drivers, aceleração de hardware e variáveis do Aquamarine/Hyprland (`AQ_DRM_DEVICES`).

### 2. Monitores e Telas
- **PROIBIDO**: Definir resoluções, taxas de atualização ou posições de monitores físicos em `dotfiles/hypr/hyprland.conf`.
- **COMO FAZER**:
  - A configuração inicial de telas fica em `local-config.nix` (`willos.local.hyprlandMonitors`).
  - O arquivo editável no sistema ativo é `~/.config/hypr/monitors.conf` (gerenciado pelo utilitário de display `nwg-displays`).

### 3. Identidade, Teclado e Localização
- Nome de usuário, nome completo, e-mail do Git, fuso horário, layout do teclado (ex: `nodeadkeys`, `abnt2`) e locale pertencem **exclusivamente** ao `local-config.nix`.
- Partições de disco, UUIDs e módulos de kernel de inicialização pertencem **exclusivamente** ao `hardware-configuration.nix`.

---

## 🛡️ Auditoria Automática
O script de automação [`scripts/rebuild.sh`](scripts/rebuild.sh) audita ativamente a base pública antes de compilar ou enviar alterações para o GitHub. Qualquer tentativa de violar esse isolamento interrompe imediatamente o rebuild.

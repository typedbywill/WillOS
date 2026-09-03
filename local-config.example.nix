# ==============================================================================
# 🛠️ WillOS - Template público de configuração local
# Copie para 'local-config.nix' e edite apenas a cópia.
# Nunca coloque valores reais neste template: 'local-config.nix' é ignorado pelo Git.
# ==============================================================================
{ lib, ... }:

{
  # Nome do host desta máquina
  networking.hostName = "minha-maquina";

  # Driver de GPU: "intel", "nvidia", "hybrid-intel-nvidia", "amd", ou "none"
  myHardware.gpu.type = "none";

  # Opções adicionais para NVIDIA (se aplicável):
  # myHardware.gpu.nvidia.open = false;                # Driver proprietário padrão
  # myHardware.gpu.nvidia.enableContainerToolkit = true; # Suporte a Docker GPU
}

# ==============================================================================
# 🛠️ WillOS - Configuração Local da Máquina (Template de Exemplo)
# Copie este arquivo para 'local-config.nix' para sobrescrever configurações locais.
# O arquivo 'local-config.nix' é ignorado pelo Git para manter a portabilidade.
# ==============================================================================
{ lib, ... }:

{
  # Nome do host desta máquina
  networking.hostName = "willos";

  # Driver de GPU: "intel", "nvidia", "hybrid-intel-nvidia", "amd", ou "none"
  myHardware.gpu.type = "intel";

  # Opções adicionais para NVIDIA (se aplicável):
  # myHardware.gpu.nvidia.open = false;                # Driver proprietário padrão
  # myHardware.gpu.nvidia.enableContainerToolkit = true; # Suporte a Docker GPU
}

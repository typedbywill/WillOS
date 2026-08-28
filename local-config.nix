# ==============================================================================
# 🛠️ WillOS - Configuração Local da Máquina (casa)
# ==============================================================================
{ lib, ... }:

{
  networking.hostName = "casa";
  myHardware.gpu.type = "nvidia";
}

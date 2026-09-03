# ==============================================================================
# 🛠️ WillOS - Template público de configuração local
# Copie para 'local-config.nix' e edite apenas a cópia.
# Nunca coloque valores reais neste template: 'local-config.nix' é ignorado pelo Git.
# ==============================================================================
{ lib, ... }:

{
  # Identidade e hardware desta máquina.
  networking.hostName = "minha-maquina";
  myHardware.gpu.type = "none";

  # Dados pessoais e preferências locais. Valores reais pertencem somente à
  # cópia local-config.nix, nunca a este template versionado.
  willos.local = {
    configured = true;
    username = "usuario";
    fullName = "Usuário Local";
    homeDirectory = "/home/usuario";
    repositoryDirectory = "/home/usuario/willos";
    gitName = "";
    gitEmail = "";
    timeZone = "UTC";
    locale = "en_US.UTF-8";
    xkbLayout = "us";
    consoleKeyMap = "us";

    # Monitores e workspaces são específicos do hardware local.
    hyprlandMonitors = ''
      monitor = ,preferred,auto,1
    '';
  };

  # Opcional: consulta o Git periodicamente e so executa o rebuild quando um
  # novo commit remoto puder ser aplicado por fast-forward com a arvore limpa.
  willos.autoSync = {
    enable = false;
    interval = "15min";
    randomizedDelay = "2min";
    action = "switch"; # Use "boot" para ativar somente no proximo boot.
  };

  # Opções adicionais para NVIDIA, se aplicável:
  # myHardware.gpu.nvidia.open = false;
  # myHardware.gpu.nvidia.enableContainerToolkit = true;
}

{ config, lib, ... }:

let
  cfg = config.willos.sunshine;
in
{
  options.willos.sunshine = {
    enable = lib.mkEnableOption "servidor de game streaming e acesso remoto Sunshine";

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Iniciar o serviço do Sunshine automaticamente no login do usuário.";
    };

    capSysAdmin = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Permitir captura KMS/KMSgrab pelo Sunshine via cap_sys_admin.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Abrir portas necessárias no firewall para o Sunshine.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.sunshine = {
      enable = true;
      autoStart = cfg.autoStart;
      capSysAdmin = cfg.capSysAdmin;
      openFirewall = cfg.openFirewall;
    };
  };
}

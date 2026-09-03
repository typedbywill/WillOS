{ config, lib, pkgs, ... }:

let
  cfg = config.willos.autoSync;
  local = config.willos.local;
  autoSync = pkgs.writeShellApplication {
    name = "willos-auto-sync";
    runtimeInputs = with pkgs; [ coreutils git gnugrep util-linux ];
    text = builtins.readFile ../scripts/auto-sync.sh;
  };
in
{
  options.willos.autoSync = {
    enable = lib.mkEnableOption "sincronizacao e rebuild automaticos do WillOS";

    interval = lib.mkOption {
      type = lib.types.str;
      default = "15min";
      description = "Intervalo entre consultas ao repositorio remoto.";
    };

    randomizedDelay = lib.mkOption {
      type = lib.types.str;
      default = "2min";
      description = "Atraso aleatorio maximo aplicado a cada consulta.";
    };

    branch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Branch remoto acompanhado pelo servico.";
    };

    action = lib.mkOption {
      type = lib.types.enum [ "switch" "boot" ];
      default = "switch";
      description = "Acao usada pelo nixos-rebuild apos uma atualizacao.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.willos-auto-sync = {
      description = "Sincronizar e aplicar atualizacoes do WillOS";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        StateDirectory = "willos-auto-sync";
        ExecStart = lib.concatStringsSep " " ([
          "${autoSync}/bin/willos-auto-sync"
        ] ++ map lib.escapeShellArg [
          local.repositoryDirectory
          local.username
          local.homeDirectory
          cfg.branch
          cfg.action
          "${pkgs.nixos-rebuild}/bin/nixos-rebuild"
        ]);
      };
    };

    systemd.timers.willos-auto-sync = {
      description = "Verificar atualizacoes do WillOS periodicamente";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = cfg.interval;
        RandomizedDelaySec = cfg.randomizedDelay;
        Persistent = true;
        Unit = "willos-auto-sync.service";
      };
    };
  };
}

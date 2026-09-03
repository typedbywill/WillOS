{ lib, ... }:

{
  options.willos.local = {
    username = lib.mkOption {
      type = lib.types.str;
      default = "user";
      description = "Nome da conta local; deve ser sobrescrito em local-config.nix";
    };

    fullName = lib.mkOption {
      type = lib.types.str;
      default = "Local User";
      description = "Nome de exibição da conta local";
    };

    homeDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/home/user";
      description = "Diretório home da conta local";
    };

    gitName = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Nome do autor Git, mantido somente na configuração local";
    };

    gitEmail = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "E-mail do autor Git, mantido somente na configuração local";
    };

    timeZone = lib.mkOption {
      type = lib.types.str;
      default = "UTC";
      description = "Fuso horário desta instalação";
    };

    locale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
      description = "Locale principal desta instalação";
    };

    xkbLayout = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "Layout XKB usado no sistema e no Hyprland";
    };

    consoleKeyMap = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "Mapa de teclado dos consoles virtuais";
    };

    hyprlandMonitors = lib.mkOption {
      type = lib.types.lines;
      default = "monitor = ,preferred,auto,1";
      description = "Configuração local de monitores e workspaces do Hyprland";
    };
  };
}

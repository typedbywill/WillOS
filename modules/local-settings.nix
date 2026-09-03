{ config, lib, ... }:

{
  options.willos.local = {
    configured = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Confirma que local-config.nix foi criado e revisado nesta máquina";
    };

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

    repositoryDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/home/user/willos";
      description = "Diretório local do checkout WillOS";
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

  config.assertions = [
    {
      assertion = config.willos.local.configured;
      message = "Crie local-config.nix a partir de local-config.example.nix antes de aplicar o WillOS.";
    }
    {
      assertion = builtins.match "[a-z_][a-z0-9_-]*" config.willos.local.username != null;
      message = "willos.local.username não é um nome de usuário Unix válido.";
    }
    {
      assertion = lib.hasPrefix "/" config.willos.local.homeDirectory;
      message = "willos.local.homeDirectory precisa ser um caminho absoluto.";
    }
    {
      assertion = lib.hasPrefix "/" config.willos.local.repositoryDirectory;
      message = "willos.local.repositoryDirectory precisa ser um caminho absoluto.";
    }
    {
      assertion = (config.willos.local.gitName == "") == (config.willos.local.gitEmail == "");
      message = "Defina willos.local.gitName e gitEmail juntos, ou deixe ambos vazios.";
    }
  ];
}

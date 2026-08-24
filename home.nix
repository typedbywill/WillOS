{ config, pkgs, lib, inputs, ... }:

{
  home.username = "william";
  home.homeDirectory = "/home/william";
  home.stateVersion = "26.05";

  # Pacotes específicos do usuário
  home.packages = with pkgs; [
    firefox
    keepassxc
    vscode
    code-cursor
    syncthing
    lmstudio
    spotify
    zapzap
    telegram-desktop
    papirus-icon-theme
    papirus-folders
    kdePackages.dolphin
    kdePackages.breeze
    kdePackages.breeze-icons
    kdePackages.qqc2-desktop-style
    kdePackages.qtsvg
    kdePackages.kimageformats
    kdePackages.kio-extras
    kdePackages.kio-admin
    kdePackages.kdegraphics-thumbnailers
    kdePackages.ffmpegthumbs
    kdePackages.ark
    libnotify
    nmap
    nodejs
    pnpm
    yarn
    bun
    moonlight-qt
    rustdesk-flutter
    socat
    jq
  ];

  # Variáveis de sessão do usuário
  home.sessionVariables = {
    BROWSER = "firefox";
    DEFAULT_BROWSER = "${pkgs.firefox}/bin/firefox";
    FILEMANAGER = "dolphin";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
  };

  # Configuração Qt para integração visual nativa com Caelestia
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "breeze";
  };

  # Associação de arquivos e protocolos para o navegador padrão e gerenciador de arquivos
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "org.kde.dolphin.desktop";
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    };
  };

  # Serviço do Syncthing em segundo plano para o usuário
  services.syncthing = {
    enable = true;
  };

  # Gerenciamento de dotfiles declarativos
  xdg.configFile."hypr/hyprland.conf" = { source = ./dotfiles/hypr/hyprland.conf; force = true; };
  xdg.configFile."hypr/scripts/auto-virtual-display.sh" = { source = ./dotfiles/hypr/scripts/auto-virtual-display.sh; force = true; executable = true; };
  xdg.configFile."kitty/kitty.conf" = { source = ./dotfiles/kitty/kitty.conf; force = true; };
  xdg.configFile."caelestia/shell.json" = { source = ./dotfiles/caelestia/shell.json; force = true; };
  xdg.configFile."caelestia/cli.json" = { source = ./dotfiles/caelestia/cli.json; force = true; };
  xdg.configFile."caelestia/sync-kde.sh" = { source = ./dotfiles/caelestia/sync-kde.sh; force = true; executable = true; };
  xdg.configFile."fish/config.fish" = { source = ./dotfiles/fish/config.fish; force = true; };
  xdg.configFile."fastfetch/config.jsonc" = { source = ./dotfiles/fastfetch/config.jsonc; force = true; };
  xdg.configFile."fuzzel/fuzzel.ini" = { source = ./dotfiles/fuzzel/fuzzel.ini; force = true; };
  xdg.configFile."cava/config" = { source = ./dotfiles/cava/config; force = true; };
  xdg.configFile."htop/htoprc" = { source = ./dotfiles/htop/htoprc; force = true; };
  xdg.configFile."dolphinrc" = { source = ./dotfiles/dolphin/dolphinrc; force = true; };
  xdg.dataFile."kxmlgui5/dolphin/dolphinui.rc" = { source = ./dotfiles/dolphin/dolphinui.rc; force = true; };

  # Sincronização automática do tema Caelestia para o KDE/Dolphin na ativação
  home.activation.syncKde = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD bash ${config.home.homeDirectory}/.config/caelestia/sync-kde.sh || true
  '';

  # Configuração de temas GTK e Cursor
  gtk = {
    enable = true;
    font = {
      name = "SF Pro Display";
      size = 11;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      size = 24;
    };
  };

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    x11.enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
  };

  # Permite que o Home Manager gerencie a si mesmo
  programs.home-manager.enable = true;
}

{ config, pkgs, lib, inputs, localSettings, ... }:

let
  chatgpt = pkgs.callPackage ./pkgs/chatgpt.nix {};
  winbox = pkgs.callPackage ./pkgs/winbox.nix {};
  mysql-workbench = pkgs.callPackage ./pkgs/mysql-workbench.nix {};
in
{
  imports = [
    ./modules/spotify-inactivity-watcher.nix
  ];

  home.username = localSettings.username;
  home.homeDirectory = localSettings.homeDirectory;
  home.stateVersion = "26.05";

  # Pacotes específicos do usuário
  home.packages = with pkgs; [
    chatgpt
    mission-center
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
    kora-icon-theme
    whitesur-icon-theme
    libreoffice-stable
    hunspell
    hunspellDicts.pt_BR
    mysql-workbench
    mongodb-compass
    postman
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
    scrcpy
    winbox
    socat
    jq
    xdg-user-dirs
    cliphist
    wl-clipboard
    fuzzel
    libsecret
  ];

  # Variáveis de sessão do usuário
  home.sessionVariables = {
    BROWSER = "firefox";
    DEFAULT_BROWSER = "${pkgs.firefox}/bin/firefox";
    FILEMANAGER = "dolphin";
    QT_QPA_PLATFORM = "wayland;xcb";
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

  # Padronização declarativa de diretórios de usuário XDG
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    desktop = "${config.home.homeDirectory}/Desktop";
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    music = "${config.home.homeDirectory}/Music";
    pictures = "${config.home.homeDirectory}/Pictures";
    videos = "${config.home.homeDirectory}/Videos";
    templates = "${config.home.homeDirectory}/Templates";
    publicShare = "${config.home.homeDirectory}/Public";
    extraConfig = {
      XDG_PROJECTS_DIR = "${config.home.homeDirectory}/Projects";
    };
  };

  # Serviço do Syncthing em segundo plano para o usuário
  services.syncthing = {
    enable = true;
  };

  # Gerenciamento de dotfiles declarativos
  xdg.configFile."hypr/hyprland.conf" = {
    force = true;
    text = builtins.replaceStrings
      [ "@WILLOS_MONITORS@" "@WILLOS_XKB_LAYOUT@" ]
      [ localSettings.hyprlandMonitors localSettings.xkbLayout ]
      (builtins.readFile ./dotfiles/hypr/hyprland.conf);
  };
  xdg.configFile."hypr/hyprlock.conf" = {
    force = true;
    text = builtins.replaceStrings
      [ "@WILLOS_LOCALE@" ]
      [ localSettings.locale ]
      (builtins.readFile ./dotfiles/hypr/hyprlock.conf);
  };
  # Desliga DPMS somente após um minuto de sessão bloqueada. `on-timeout` e
  # `on-resume` ficam no mesmo listener para a primeira entrada religar as telas.
  xdg.configFile."hypr/hypridle.conf".text = ''
    listener {
      timeout = 60
      condition_cmd = caelestia shell lock isLocked 2>/dev/null | grep -qx true
      on-timeout = hyprctl dispatch dpms off
      on-resume = hyprctl dispatch dpms on
    }
  '';
  xdg.configFile."hypr/scripts/lock-with-dpms.sh" = { source = ./dotfiles/hypr/scripts/lock-with-dpms.sh; force = true; executable = true; };
  xdg.configFile."hypr/scripts/auto-virtual-display.sh" = { source = ./dotfiles/hypr/scripts/auto-virtual-display.sh; force = true; executable = true; };
  xdg.configFile."hypr/scripts/workspace-compactor.sh" = { source = ./dotfiles/hypr/scripts/workspace-compactor.sh; force = true; executable = true; };
  xdg.configFile."hypr/scripts/workspace.sh" = { source = ./dotfiles/hypr/scripts/workspace.sh; force = true; executable = true; };
  xdg.configFile."hypr/scripts/toggle-special.sh" = { source = ./dotfiles/hypr/scripts/toggle-special.sh; force = true; executable = true; };
  xdg.configFile."hypr/scripts/cycle-audio-source.sh" = { source = ./dotfiles/hypr/scripts/cycle-audio-source.sh; force = true; executable = true; };
  xdg.configFile."kitty/kitty.conf" = { source = ./dotfiles/kitty/kitty.conf; force = true; };
  xdg.configFile."caelestia/shell.json" = { source = ./dotfiles/caelestia/shell.json; force = true; };
  xdg.configFile."caelestia/cli.json" = { source = ./dotfiles/caelestia/cli.json; force = true; };
  xdg.configFile."caelestia/sync-kde.sh" = { source = ./dotfiles/caelestia/sync-kde.sh; force = true; executable = true; };
  xdg.configFile."fish/config.fish" = { source = ./dotfiles/fish/config.fish; force = true; };
  xdg.configFile."scripts/rebuild.sh" = { source = ./scripts/rebuild.sh; force = true; executable = true; };
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

  # Garante a existência do arquivo de esquema de cores para o Hyprland não falhar no boot
  home.activation.ensureHyprScheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SCHEME_DIR="${config.home.homeDirectory}/.config/hypr/scheme"
    SCHEME_FILE="$SCHEME_DIR/current.conf"
    mkdir -p "$SCHEME_DIR"
    if [ ! -f "$SCHEME_FILE" ]; then
      cp -f ${./dotfiles/hypr/scheme/default.conf} "$SCHEME_FILE" || true
    fi
  '';

  # A topologia dos monitores varia por máquina. Cria um ponto de partida local
  # somente na primeira ativação e preserva quaisquer ajustes posteriores.
  home.activation.ensureHyprMonitorConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    MONITORS_FILE="${config.home.homeDirectory}/.config/hypr/monitors.conf"
    if [ ! -e "$MONITORS_FILE" ]; then
      install -m 600 ${./dotfiles/hypr/monitors.conf.example} "$MONITORS_FILE"
    fi
  '';

  # Garante layout moderno e limpo para o Dolphin sem painéis sobrepostos
  home.activation.ensureDolphinState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    STATE_DIR="${config.home.homeDirectory}/.local/state"
    mkdir -p "$STATE_DIR"
    cat << 'EOF' > "$STATE_DIR/dolphinstaterc"
[FilterBar]
caseSensitive=false
filterMode=1

[State]
State=AAAA/wAAAAD9AAAAAwAAAAAAAAAAAAAAAPwCAAAAAvsAAAAUAHAAbABhAGMAZQBzAEQAbwBjAGsBAAAAAP////8AAAAeAP////sAAAAWAGYAbwBsAGQAZQByAHMARABvAGMAawAAAAAA/////wAAAB4A////AAAAAQAAAAAAAAAA/AIAAAAB+wAAABAAaQBuAGYAbwBEAG8AYwBrAAAAAAD/////AAAAHgD///8AAAADAAAAAAAAAAD8AQAAAAH7AAAAGAB0AGUAcgBtAGkAbgBhAGwARABvAGMAawAAAAAA/////wAAAFwA////AAAAAAAAAAAAAAAEAAAABAAAAAgAAAAI/AAAAAEAAAACAAAAAQAAABYAbQBhAGkAbgBUAG8AbwBsAEIAYQByAQAAAAD/////AAAAAAAAAAA=
EOF
  '';

  # Configuração de temas GTK, Marcadores e Cursor
  gtk = {
    enable = true;
    font = {
      name = "SF Pro Display";
      size = 11;
    };
    iconTheme = {
      # WhiteSur replica a linguagem visual de ícones do macOS (Big Sur).
      name = "WhiteSur-dark";
      package = pkgs.whitesur-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      size = 24;
    };
    gtk3.bookmarks = [
      "file://${config.home.homeDirectory}/Documents Documents"
      "file://${config.home.homeDirectory}/Downloads Downloads"
      "file://${config.home.homeDirectory}/Pictures Pictures"
      "file://${config.home.homeDirectory}/Music Music"
      "file://${config.home.homeDirectory}/Videos Videos"
      "file://${config.home.homeDirectory}/Projects Projects"
    ];
  };

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    x11.enable = true;
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
  };

  # Configuração declarativa do Git com GNOME Keyring / Libsecret
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    settings = {
      credential = {
        helper = "libsecret";
      };
    } // lib.optionalAttrs (localSettings.gitName != "" && localSettings.gitEmail != "") {
      user = {
        name = localSettings.gitName;
        email = localSettings.gitEmail;
      };
    };
  };

  # Permite que o Home Manager gerencie a si mesmo
  programs.home-manager.enable = true;
}

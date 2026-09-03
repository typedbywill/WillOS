{ config, pkgs, lib, inputs, ... }:

let
  local = config.willos.local;
in
{
  imports = [
    ./modules/local-settings.nix
    ./modules/gpu.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "ntfs" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking.hostName = lib.mkDefault "willos";
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    checkReversePath = "loose";
    trustedInterfaces = [ "tailscale0" ];
    allowedTCPPorts = [ 21118 ];
    allowedUDPPorts = [ 21118 ];
  };

  # Habilita o serviço Tailscale
  services.tailscale.enable = true;
  time.timeZone = local.timeZone;

  # Habilita execução de binários não-nix pré-compilados
  programs.nix-ld.enable = true;

  i18n.defaultLocale = local.locale;
  i18n.extraLocaleSettings = lib.genAttrs [
    "LC_ADDRESS"
    "LC_IDENTIFICATION"
    "LC_MEASUREMENT"
    "LC_MONETARY"
    "LC_NAME"
    "LC_NUMERIC"
    "LC_PAPER"
    "LC_TELEPHONE"
    "LC_TIME"
  ] (_: local.locale);

  services.xserver.xkb.layout = local.xkbLayout;
  console.keyMap = local.consoleKeyMap;

  # Ativa o NumLock nos TTYs/consoles virtuais durante a inicialização
  systemd.services.numLockOnTty = {
    description = "Ativar NumLock nos TTYs";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "numlock-on-tty" ''
        for tty in /dev/tty[1-6]; do
          ${pkgs.kbd}/bin/setleds -D +num < "$tty" 2>/dev/null || true
        done
      '';
      Type = "oneshot";
    };
  };

  users.users.${local.username} = {
    isNormalUser = true;
    description = local.fullName;
    home = local.homeDirectory;
    extraGroups = [ "networkmanager" "wheel" "i2c" "docker" "uinput" "input" "libvirtd" "kvm" ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Sessão Wayland com integração systemd; o Caelestia é iniciado pelo Hyprland.
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
  programs.hyprlock.enable = true;

  # Evita que a terminação de um processo filho por OOM encerre toda a sessão do Hyprland
  systemd.user.services."wayland-wm@" = {
    serviceConfig = {
      OOMPolicy = "continue";
    };
  };

  # Swap comprimido em RAM (zram) com 100% do tamanho da memória RAM
  zramSwap = {
    enable = true;
    memoryPercent = 100;
    algorithm = "zstd";
    priority = 10;
  };

  programs.dconf.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
  security.polkit.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # Habilita o daemon GNOME Keyring e integração PAM para desbloqueio automático no login
  services.gnome.gnome-keyring.enable = true;
  programs.seahorse.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.hyprlock.enableGnomeKeyring = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };
  hardware.i2c.enable = true;

  # Virtualização, KVM/QEMU, Libvirt e Docker
  virtualisation = {
    docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };

  programs.virt-manager.enable = true;

  # Desativação completa de suspensão, hibernação e sleep no nível do sistema
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Desativa ações automáticas de economia de energia e suspensão do systemd-logind
  services.logind.settings.Login = {
    HandleSuspendKey = "ignore";
    HandleHibernateKey = "ignore";
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    IdleAction = "ignore";
  };

  # Habilita suporte a Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # Servidor OpenSSH (sshd)
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
    openFirewall = true;
  };

  # Servidor de streaming e acesso remoto Sunshine
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      theme = "sddm-astronaut-theme";
      extraPackages = with pkgs.kdePackages; [
        qtsvg
        qtmultimedia
        qtvirtualkeyboard
      ];
    };
    autoLogin = {
      enable = true;
      user = local.username;
    };
    defaultSession = "hyprland-uwsm";
  };

  environment.systemPackages = with pkgs; [
    gitFull
    gh
    libsecret
    wget
    curl
    efibootmgr
    docker-compose
    kitty
    fish
    fastfetch
    wl-clipboard
    fuzzel
    grim
    slurp
    swappy
    pavucontrol
    brightnessctl
    ddcutil
    playerctl
    networkmanagerapplet
    material-symbols
    nerd-fonts.caskaydia-cove
    bibata-cursors
    sddm-astronaut
    cloudflared
    android-tools
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    virtio-win
    qbittorrent
    inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli
    inputs.caelestia-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
    (pkgs.writeShellScriptBin "rebuild" ''
      for p in "$HOME/willos/scripts/rebuild.sh" "$HOME/WillOS/scripts/rebuild.sh" "$HOME/.config/scripts/rebuild.sh"; do
        if [ -f "$p" ]; then
          exec bash "$p" "$@"
        fi
      done
      echo "❌ Script de rebuild não encontrado em $HOME/willos/scripts/rebuild.sh nem em $HOME/WillOS/scripts/rebuild.sh" >&2
      exit 1
    '')
  ];

  # Serviço do Cloudflare Tunnel (Inicia automaticamente apenas se o arquivo de token existir)
  systemd.services.cloudflared = {
    description = "Cloudflare Tunnel Daemon";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig = {
      ConditionPathExists = [
        "|/etc/cloudflared.env"
        "|${local.homeDirectory}/.config/cloudflared/tunnel.env"
      ];
    };
    serviceConfig = {
      EnvironmentFile = [
        "-/etc/cloudflared.env"
        "-${local.homeDirectory}/.config/cloudflared/tunnel.env"
      ];
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run";
      Restart = "always";
      RestartSec = "10s";
    };
  };

  fonts = {
    packages = with pkgs; [
      material-symbols
      nerd-fonts.caskaydia-cove
      inputs.apple-fonts.packages.${pkgs.stdenv.hostPlatform.system}.sf-pro
      inputs.apple-fonts.packages.${pkgs.stdenv.hostPlatform.system}.sf-mono-nerd
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = [ "SF Pro Display" "SF Pro Text" "DejaVu Sans" ];
        serif = [ "New York" "DejaVu Serif" ];
        monospace = [ "SF Mono" "CaskaydiaCove Nerd Font" "monospace" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  environment.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "Bibata-Modern-Ice";
    HYPRCURSOR_SIZE = "24";
    TERMINAL = "kitty";
  };

  system.stateVersion = "26.05";
}

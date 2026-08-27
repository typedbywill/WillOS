{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./modules/gpu.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "ntfs" ];

  networking.hostName = lib.mkDefault "nixos";
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 21118 ];
    allowedUDPPorts = [ 21118 ];
  };
  time.timeZone = "America/Sao_Paulo";

  # Habilita execução de binários não-nix pré-compilados
  programs.nix-ld.enable = true;

  i18n.defaultLocale = "pt_BR.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  services.xserver.xkb.layout = "br";
  console.keyMap = "br-abnt2";

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

  users.users.william = {
    isNormalUser = true;
    description = "William";
    extraGroups = [ "networkmanager" "wheel" "i2c" "docker" "uinput" "input" ];
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
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };
  hardware.i2c.enable = true;

  # Virtualização e Docker
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

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
      user = "william";
    };
    defaultSession = "hyprland-uwsm";
  };

  environment.systemPackages = with pkgs; [
    git
    gh
    wget
    curl
    efibootmgr
    docker-compose
    kitty
    fish
    fastfetch
    wl-clipboard
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
    inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli
    inputs.caelestia-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
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
        "|/home/william/.config/cloudflared/tunnel.env"
      ];
    };
    serviceConfig = {
      EnvironmentFile = [
        "-/etc/cloudflared.env"
        "-/home/william/.config/cloudflared/tunnel.env"
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
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "Bibata-Modern-Classic";
    HYPRCURSOR_SIZE = "24";
    TERMINAL = "kitty";
  };

  system.stateVersion = "26.05";
}

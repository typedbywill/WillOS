{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
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

  users.users.william = {
    isNormalUser = true;
    description = "William";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Sessão Wayland com integração systemd; o Caelestia é iniciado pelo Hyprland.
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  programs.dconf.enable = true;
  security.polkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };
  hardware.graphics.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      user = "william";
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd 'uwsm start hyprland-uwsm.desktop'";
    };
  };

  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    kitty
    fish
    fastfetch
    wl-clipboard
    grim
    slurp
    swappy
    pavucontrol
    brightnessctl
    playerctl
    networkmanagerapplet
    material-symbols
    nerd-fonts.caskaydia-cove
    bibata-cursors
    inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli
    inputs.caelestia-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

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

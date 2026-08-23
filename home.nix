{ config, pkgs, inputs, ... }:

{
  home.username = "william";
  home.homeDirectory = "/home/william";
  home.stateVersion = "26.05";

  # Permite pacotes proprietários (unfree) no Home Manager
  nixpkgs.config.allowUnfree = true;

  # Pacotes específicos do usuário
  home.packages = with pkgs; [
    firefox
  ];

  # Gerenciamento de dotfiles declarativos
  xdg.configFile."hypr/hyprland.conf".source = ./dotfiles/hypr/hyprland.conf;
  xdg.configFile."kitty/kitty.conf".source = ./dotfiles/kitty/kitty.conf;
  xdg.configFile."caelestia/shell.json".source = ./dotfiles/caelestia/shell.json;
  xdg.configFile."fish/config.fish".source = ./dotfiles/fish/config.fish;
  xdg.configFile."fastfetch/config.jsonc".source = ./dotfiles/fastfetch/config.jsonc;
  xdg.configFile."fuzzel/fuzzel.ini".source = ./dotfiles/fuzzel/fuzzel.ini;
  xdg.configFile."cava/config".source = ./dotfiles/cava/config;
  xdg.configFile."htop/htoprc".source = ./dotfiles/htop/htoprc;

  # Configuração de temas GTK e Cursor
  gtk = {
    enable = true;
    font = {
      name = "SF Pro Display";
      size = 11;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      size = 24;
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
  };

  # Permite que o Home Manager gerencie a si mesmo
  programs.home-manager.enable = true;
}

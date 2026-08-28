{
  description = "WillOS - NixOS com Hyprland e Caelestia Shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    caelestia-cli = {
      url = "github:caelestia-dots/cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
  let
    mkWillOS = { extraModules ? [] }: nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        (if builtins.pathExists ./hardware-configuration.nix then ./hardware-configuration.nix else {})
        (if builtins.pathExists ./local-config.nix then ./local-config.nix else {})
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.william = import ./home.nix;
        }
      ] ++ extraModules;
    };
  in {
    nixosConfigurations = {
      willos = mkWillOS {};
      default = self.nixosConfigurations.willos;
      # Aliases para retrocompatibilidade
      notegiga = self.nixosConfigurations.willos;
      casa = self.nixosConfigurations.willos;
      nixos = self.nixosConfigurations.willos;
    };
  };
}

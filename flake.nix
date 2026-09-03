{
  description = "WillOS - NixOS com Hyprland e Caelestia Shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "github:outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.quickshell.follows = "quickshell";
    };
    caelestia-cli = {
      url = "github:caelestia-dots/cli";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.caelestia-shell.follows = "caelestia-shell";
    };
    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
  let
    resolveLocalModule = name:
      let
        pwdPath = if builtins.getEnv "PWD" != "" then (/. + (builtins.getEnv "PWD") + "/${name}") else null;
        flakeDirPath = if builtins.getEnv "FLAKE_DIR" != "" then (/. + (builtins.getEnv "FLAKE_DIR") + "/${name}") else null;
        etcPath = /. + "/etc/nixos/${name}";
      in
        if builtins.pathExists (./. + "/${name}") then (./. + "/${name}")
        else if pwdPath != null && builtins.pathExists pwdPath then pwdPath
        else if flakeDirPath != null && builtins.pathExists flakeDirPath then flakeDirPath
        else if builtins.pathExists etcPath then etcPath
        else {};

    mkWillOS = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        (resolveLocalModule "hardware-configuration.nix")
        (resolveLocalModule "local-config.nix")
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.william = import ./home.nix;
        }
      ];
    };
  in {
    nixosConfigurations = {
      # Existe um único sistema público. Identidade e hardware da máquina são
      # injetados pelos arquivos locais ignorados pelo Git acima.
      willos = mkWillOS;
    };
  };
}

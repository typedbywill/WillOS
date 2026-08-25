{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "laptop";
  myHardware.gpu.type = lib.mkDefault "intel";
}

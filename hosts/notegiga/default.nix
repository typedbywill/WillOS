{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "notegiga";
  myHardware.gpu.type = lib.mkDefault "intel";
}

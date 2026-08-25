{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "casa";
  myHardware.gpu.type = lib.mkDefault "nvidia";
}

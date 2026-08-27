# Gerado a partir da configuração atual desta máquina; mantenha-o junto ao flake.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "uas" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/7fa6db06-b42b-49bf-afc3-763787f91203";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/742E-4962";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  fileSystems."/mnt/Dados" = {
    device = "/dev/disk/by-uuid/1AC43C3FC43C2005";
    fsType = "ntfs";
    options = [ "rw" "uid=1000" "gid=100" "dmask=0022" "fmask=0133" "nofail" ];
  };

  fileSystems."/mnt/DadosLinux" = {
    device = "/dev/disk/by-uuid/fa2ac10d-121a-4fdb-9e08-6b46ed74ca66";
    fsType = "ext4";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/a86dfe49-531f-45f5-9762-5ed8e86451f7"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  myHardware.gpu.type = lib.mkDefault "nvidia";
}

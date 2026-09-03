{ config, lib, pkgs, ... }:

let
  cfg = config.myHardware.gpu;
in
{
  options.myHardware.gpu = {
    type = lib.mkOption {
      type = lib.types.enum [ "intel" "nvidia" "hybrid-intel-nvidia" "amd" "none" ];
      default = "none";
      description = "Tipo de GPU da máquina: 'intel', 'nvidia', 'hybrid-intel-nvidia', 'amd', ou 'none'";
    };
    nvidia = {
      enableContainerToolkit = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Habilitar Nvidia Container Toolkit (CDI) para Docker quando a GPU Nvidia estiver ativa";
      };
      open = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Usar módulo de kernel open-source da NVIDIA";
      };
    };
  };

  config = lib.mkMerge [
    # Aceleração gráfica base
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };
    }

    # Perfil: Intel
    (lib.mkIf (cfg.type == "intel" || cfg.type == "hybrid-intel-nvidia") {
      hardware.graphics.extraPackages = with pkgs; [
        intel-media-driver
        vpl-gpu-rt
      ];
    })

    # Perfil: NVIDIA
    (lib.mkIf (cfg.type == "nvidia" || cfg.type == "hybrid-intel-nvidia") {
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        powerManagement.finegrained = false;
        open = cfg.nvidia.open;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };

      hardware.nvidia-container-toolkit.enable = cfg.nvidia.enableContainerToolkit;

      # O módulo registra os dispositivos NVIDIA; este helper privilegiado cria
      # os nós /dev/nvidia* necessários para CUDA e nvidia-smi.
      environment.systemPackages = [ pkgs.nvidia-modprobe ];
      security.wrappers.nvidia-modprobe = {
        source = "${pkgs.nvidia-modprobe}/bin/nvidia-modprobe";
        owner = "root";
        group = "root";
        setuid = true;
      };

      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "nvidia";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        NVD_BACKEND = "direct";
      };
    })

    # Perfil: AMD
    (lib.mkIf (cfg.type == "amd") {
      services.xserver.videoDrivers = [ "amdgpu" ];
      hardware.graphics.extraPackages = with pkgs; [
        amdvlk
      ];
      hardware.graphics.extraPackages32 = with pkgs; [
        driversi686Linux.amdvlk
      ];
    })
  ];
}

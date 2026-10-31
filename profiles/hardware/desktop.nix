{ config }: {
  nixpkgs.hostPlatform = "x86_64-linux";
  hardware = {
    graphics.enable = true;
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      open = true;
      powerManagement.enable = true;
      powerManagement.finegrained = false;
      nvidiaSettings = true;
    };
  };

  boot.initrd.availableKernelModules = [
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia"
    "nvidia_uvm"
  ];

  boot.blacklistedKernelModules = [ "nouveau" ];

  boot.kernelParams = [
    "nvidia.NVreg_PreserveVideoMemoryAllocation=1"
  ];

  services.xserver.videoDrivers = [ "nvidia" ];
  
  disko.devices.disk.primary.device = "/dev/disk/by-label/nvme-eui.e8238fa6bf530001001b448b4c504ccd";
}

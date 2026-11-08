{ config, ... }: {
  hardware = {
    graphics.enable = true;
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
      modesetting.enable = true;
      open = true;
      powerManagement = {
        enable = true;
        finegrained = true;
      };
    };
  };

  boot.blacklistedKernelModules = [ "nouveau" ];

  disko.devices.disk.primary.device = "/dev/disk/by-id/nvme-eui.002538b971031fda";
  disko.devices.disk.secondary.device = "/dev/disk/by-id/wwn-0x5000cca8d8ec939a";
}

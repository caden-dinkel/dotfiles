{config, ... }: {
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
  
  nixpkgs.hostPlatform = "x86_64-linux";

}

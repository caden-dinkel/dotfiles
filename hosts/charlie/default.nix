{
    system.stateVersion = "26.05";
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    networking.hostName = "charlie";
    nixpkgs.hostPlatform = "x86_64-linux";
    hardware = {
        graphics.enable = true;
        nvidia = { 
            package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
            modesetting.enable = true;
            open = true;
        };
    };
    disko.devices.disk.primary.device = "/dev/disk/by-id/nvme-eui.002538b971031fda";
    disko.devices.disk.secondary.device = "/dev/disk/by-id/wwn-0x5000cca8d8ec939a";
}
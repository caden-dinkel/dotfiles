{ config, name, git, pkgs, home-manager, ... }:
{
    imports = [
        ../../modules/common.nix
        home-manager.nixosModules.home-manager
        ../../modules/home.nix
    ];

    # Allows non-root to execute root commands using sudo
    security.sudo.enable = true;
    system.stateVersion = "26.05";
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    networking.hostName = "bravo";
    nixpkgs.hostPlatform = "x86_64-linux";
    hardware = {
        graphics.enable = true;
        nvidia = { 
            package = config.boot.kernelPackages.nvidiaPackages.stable;
            modesetting.enable = true;
            open = true;
        };
    };

    # Primary, secondary, ternary, ... naming scheme.
    disko.devices.disk.primary.device = "/dev/disk/by-label/nvme-eui.e8238fa6bf530001001b448b4c504ccd";

    users.users.${name} = {
        isNormalUser = true;
    };

    services.desktopManager.gnome.enable = true;
    services.displayManager.gdm.enable = true;

    services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
    };
}
{ config, name, pkgs, home-manager, ... }:
{
    imports = [
        ./hardware-configuration.nix
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
    disko.devices.disk.primary = {
        type = "disk";
        content = {
            type = "gpt";
            partitions = {
                ESP = {
                    priority = 1;
                    name = "ESP";
                    start = "1M";
                    end = "1G";
                    type = "EF00";
                    content = {
                        type = "filesystem";
                        format = "vfat";
                        mountpoint = "/boot";
                        mountOptions = [ "umask=0077" ];
                    };
                };
                swap = {
                    priority = 2;
                    size = "32G";
                    content = {
                        type = "swap";
                        discardPolicy = "both";
                        resumeDevice = true;
                    };
                };
                root = {
                    priority = 3;
                    size = "100%";
                    content = {
                        type = "btrfs";
                        subvolumes = {
                            "/rootfs" = {
                                mountpoint = "/";
                                mountOptions = [ "compress=zstd" "noatime" ];
                            };
                            "/home" = {
                                mountOptions = [ "compress=zstd" ];
                                mountpoint = "/home";
                            };
                            "/nix" = {
                                mountOptions = [ "compress=zstd" "noatime" ];
                                mountpoint = "/nix";
                            };
                            "/root_blank" = {};
                            "/persist" = {
                                mountpoint = "/persist";
                                mountOptions = [ "compress=zstd" "noatime" ];
                            };
                        };
                    };
                };
            };
        };
    };

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
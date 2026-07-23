{ config, lib, pkgs, ... }:

with lib;

let 
    cfg = config.myHardware.storage;
in
{
    options.myHardware.storage = {
        enable = mkEnableOption "Common storage layouts.";

        main = {
            enable = mkEnableOption "Main OS storage drive.";
            device = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "/dev/nvme0n1";
                description = "Device hosting the operating system.";
            };
            format = mkOption {
                type = types.enum [ "ext4" "btrfs" ];
                default = "ext4";
                description = "Backend for the partition on the storage drive.";
            };
            ESP = {
                enable = mkEnableOption "Enable ESP partition on main OS storage drive.";
                size = mkOption {
                    type = types.str;
                    default = "1G";
                    description = "Size of the ESP partition.";
                };
            };
            swap =  {
                enable = mkEnableOption "Swap file.";

                size = mkOption {
                    type = types.str;
                    default = "8G";
                    description = "Size of swap partition to make.";
                };
            };
        };

        secondary = {
            enable = mkEnableOption "Secondary drive for data.";
            device = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Secondary device available to host.";
            };
            format = mkOption {
                type = types.enum [ "ext4" ];
                default = "ext4";
                description = "Backend for the partition on the storage drive.";
            };
        };
    };
    config = mkIf cfg.enable {
    assertions = [
        {
        assertion = cfg.main.enable -> (cfg.main.device != null);
        message = ''
            myHardware.storage.main.enable is true, but
            myHardware.storage.main.device is not set.
        '';
        }

        {
        assertion = cfg.secondary.enable -> (cfg.secondary.device != null);
        message = ''
            myHardware.storage.secondary.enable is true, but
            myHardware.storage.secondary.device is not set.
        '';
        }
    ];

    disko.devices = {
        disk = {

        main = mkIf cfg.main.enable {
            device = cfg.main.device;
            type = "disk";

            content = {
            type = "gpt";

            partitions = {

                ESP = mkIf cfg.main.ESP.enable {
                size = cfg.main.ESP.size;
                priority = 1;
                type = "EF00";

                content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                };
                };

                swap = mkIf cfg.main.swap.enable {
                size = cfg.main.swap.size;
                priority = 2;

                content = {
                    type = "swap";
                    discardPolicy = "both";
                    resumeDevice = true;
                };
                };

                nixos = {
                priority = 3;
                size = "100%";

                content = {
                    type = "filesystem";
                    format = cfg.main.format;
                    mountpoint = "/nix";
                };
                };
            };
            };
        };

        secondary = mkIf cfg.secondary.enable {
            device = cfg.secondary.device;
            type = "disk";

            content = {
            type = "gpt";

            partitions.data = {
                size = "100%";

                content = {
                type = "filesystem";
                format = cfg.secondary.format;
                mountpoint = "/storage";
                };
            };
            };
        };
        };
    };
    };

}
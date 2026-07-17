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

        persistent = {
            enable = mkEnableOption "Secondary drive for persistent data.";
            device = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Secondary device to persist data.";
            };
            format = mkOption {
                type = types.enum [ "ext4" ];
                default = "ext4";
                description = "Backend for the partition on the storage drive."; # Fixed: Added missing semicolon
            };
        };

        ephemeral = {
            enable = mkEnableOption "Ephemeral host via tmpfs.";

            tmpfsSize = mkOption {
                type = types.str;
                default = "4G";
                description = "Amount of resources reserved for the root fs.";
            };

            persistentDirectories = mkOption {
                type = types.listOf types.str;
                default = [];
                description = "Directories on the root filesystem to persist across reboots.";
                example = [ "/var/lib/tailscale" ];
            };
        };
    };

    config = mkIf cfg.enable {
        # Nicer error-handling assertions
        assertions = [
            {
                assertion = cfg.main.enable -> (cfg.main.device != null);
                message = "myHardware.storage.main.enable is true, but myHardware.storage.main.device is not set.";
            }
            {
                assertion = cfg.persistent.enable -> (cfg.persistent.device != null);
                message = "myHardware.storage.persistent.enable is true, but myHardware.storage.persistent.device is not set.";
            }
            {
                assertion = cfg.ephemeral.enable -> (cfg.main.enable || cfg.persistent.enable);
                message = "Using an ephemeral root (tmpfs) typically requires a persistent backend storage drive or a main drive to store state safely.";
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
                                    extraArgs = [ "-O" "neededForBoot" ];
                                };
                            };

                            swap = mkIf cfg.main.swap.enable {
                                size = cfg.main.swap.size;
                                priority = 2;
                                content = {
                                    type = "swap";
                                    discardPolicy = "both";
                                    resumeDevice = true; # Note: Disko usually expects a boolean here, not a string "true"                                
                                };
                            };

                            nixos = {
                                priority = 3;
                                size = "100%";
                                content = {
                                    type = "filesystem";
                                    format = "ext4";
                                    mountpoint = "/nix";
                                };
                            };
                        };
                    };
                };

                persistent = mkIf cfg.persistent.enable {
                    device = cfg.persistent.device;
                    type = "disk";
                    content = {
                        type = "gpt";
                        partitions = {
                            data = {
                                size = "100%";
                                content = {
                                    type = "filesystem";
                                    format = cfg.persistent.format;
                                    mountpoint = "/persistent";
                                };
                            };
                        };
                    };
                };
            };

            nodev."/" = mkIf cfg.ephemeral.enable {
                fsType = "tmpfs";
                mountOptions = [ "size=${cfg.ephemeral.tmpfsSize}" "mode=755" ];
            };

        };

        systemd.tmpfiles.rules = mkIf cfg.ephemeral.enable (
            map (dir: "d /persistent${dir} 0755 root root -") cfg.ephemeral.persistentDirectories
        );

        fileSystems = mkIf cfg.ephemeral.enable (
            listToAttrs (map (dir: {
                name = dir;
                value = {
                    device = "/persistent${dir}";
                    options = [ "bind" ];
                    depends = [ "/persistent" ];
                };
            }) cfg.ephemeral.persistentDirectories)
        );
    };
}
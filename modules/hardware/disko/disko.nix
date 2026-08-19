{ config, lib, inputs, ... }:

let
  cfg = config.myHardware.disk;
in

{
  imports = [
    inputs.impermanence.nixosModule.impermanence
    ./ephemeral
  ];

  options.myHardware.disk = {
    enable = lib.mkEnableOption "Disko based disk formatting.";

    main = {
      enable = lib.mkEnableOption "Enable Disko based formatting of the main OS disk.";

      device = lib.mkOption {
        type = lib.types.oneOf [
          lib.types.str
          lib.types.path
        ];
        example = "/dev/sda";
        description = "Main disk path/name/identifier.";
      };

      ephemeral = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
        description = "Root directory on main OS is ephemeral (uses Btrfs subvolumes).";
      };

      swap = {
        enable = lib.mkEnableOption "Enable swap partition on main disk.";
        size = lib.mkOption {
          type = lib.types.str;
          default = "8G";
          example = "8G";
          description = "Size of the swap partition.";
        };
      };
    };

    secondary = {
      enable = lib.mkEnableOption "Enable Disko configuration for secondary drive";
      device = lib.mkOption {
        type = lib.types.oneOf [
          lib.types.str
          lib.types.path
        ];
        example = "/dev/sdb";
        description = "Secondary disk path/name/identifier.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.enable -> cfg.main.enable || cfg.secondary.enable;
        message = "myHardware.disk.enable is true, but neither myHardware.disk.main.enable or myHardware.disk.secondary.enable are set as true.";
      }
      {
        assertion = cfg.main.enable -> cfg.main.device != "";
        message = "myHardware.disk.main.enable is true, but 'myHardware.disk.main.device' is not set!";
      }
      {
        assertion = cfg.main.swap.enable -> cfg.main.swap.size != "";
        message = "Enabling a swap partition requires specifying a partition size.";
      }
      {
        assertion = cfg.secondary.enable -> cfg.secondary.device != "";
        message = "myHardware.disk.secondary.enable is true, but 'myHardware.disk.secondary.device' is not set!";
      }
    ];

    disko.devices = {
      disk = {
        main = lib.mkIf cfg.main.enable {
          type = "disk";
          device = cfg.main.device;
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
            } // lib.optionalAttrs cfg.main.swap.enable {
              swap = {
                priority = 2;
                size = cfg.main.swap.size;
                content = {
                  type = "swap";
                  discardPolicy = "both";
                  resumeDevice = false;
                };
              };
            } // {
              root = {
                priority = 3;
                size = "100%";
                content = if cfg.main.ephemeral then {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/root_blank" = {};
                  };
                } else {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };

        secondary = lib.mkIf cfg.secondary.enable {
          type = "disk";
          device = cfg.secondary.device;
          content = {
            type = "gpt";
            partitions.data = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "btrfs";
                mountpoint = "/storage";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
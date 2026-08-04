{ config, lib, ... }:

let
  cfg = config.myHardware.disk;
in
{
  options.myHardware.disk = {
    mainDevice = lib.mkOption {
      type = lib.types.str;
      example = "/dev/nvme0n1";
      description = "The primary disk device path.";
    };

    enableSecondary = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to configure a secondary data drive.";
    };

    secondaryDevice = lib.mkOption {
      type = lib.types.str;
      default = "/dev/sda";
      example = "/dev/sdb";
      description = "The secondary disk device path.";
    };

    swapSize = lib.mkOption {
      type = lib.types.str;
      default = "16G";
      description = "Size of the swap partition.";
    };
  };

  config = {
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = cfg.mainDevice;
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
                size = cfg.swapSize;
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
                  extraArgs = [ "-f" ];
                  type = "btrfs";
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
                };
              };
            };
          };
        };
      } // lib.optionalAttrs cfg.enableSecondary {
        secondary = {
          type = "disk";
          device = cfg.secondaryDevice;
          content = {
            type = "gpt";
            partitions.data = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "btrfs";
                mountpoint = "/storage";
              };
            };
          };
        };
      };
    };

    fileSystems."/persist".neededForBoot = true;
  };
}
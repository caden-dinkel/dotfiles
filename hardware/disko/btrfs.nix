{
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

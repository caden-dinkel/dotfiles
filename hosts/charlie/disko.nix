{  isVm ? false, lib, useHostFS ? false, ... }:
lib.mkIf (!useHostFS){
  disko.devices.disk.secondary = {
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        backups = {
          size = "100%";
          content = {
            type = "btrfs";
            subvolumes = {
              "/backups" = {
                mountpoint = "/backups";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/backups/root" = {

              };
              "/backups/server_data" = {

              };
            };
          };
        };
      };
    };
  };
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
        swap = lib.mkIf (!isVm){
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
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/nix" = {
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
                mountpoint = "/nix";
              };
              "/root_blank" = { };
              "/persist" = {
                mountpoint = "/persist";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
            };
          };
        };
      };
    };
  };
}
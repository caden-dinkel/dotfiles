{ config, lib, ... }:

let
  cfg = config.myHardware.disk;
in
{
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
  };
  config = lib.mkIf cfg.enable {
    disko.devices.disk.main = lib.mkIf cfg.main.enable {
      type = "disk";
      device = cfg.main.device;
      content = {
        type = "gpt";
        partitions = {
          ESP = import ./boot.nix;
          swap = import ./swap.nix;
          root = {
            priority = 3;
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}

/*
partitions = lib.mkOption {
  type = lib.types.listOf (lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Name of the partition.";
      };
      size = lib.mkOption {
        type = lib.types.str;
        default = "100%";
        description = "Size of the partition (e.g., '50G', '100%').";
      };
      fsType = lib.mkOption {
        type = lib.types.enum [ "ext4" "btrfs" "xfs" "swap" ];
        default = "btrfs";
        description = "Filesystem type for the partition.";
      };
      mountpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Mount point for the filesystem.";
      };
    };
  });
  default = [];
  description = "Additional custom partitions to create on the drive.";
};
*/
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
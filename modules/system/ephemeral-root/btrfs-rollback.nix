# I should consider cleaning this script up a bit.

{
    boot.initrd.systemd.services.rollback = {
        description = "Rollback BTRFS root subvolume to a pristine state";
        wantedBy = [ "initrd.target" ];
        after = [ "initrd-root-device.target" ];
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = ''
            mkdir -p /btrfs_tmp
            rootDevice=/dev/disk/by-partlabel/root

            mount -t btrfs -o subvolid=5 "$rootDevice" /btrfs_tmp
            
            # Delete the old root subvolume if it exists
            if [[ -e /btrfs_tmp/root ]]; then
                btrfs subvolume delete /btrfs_tmp/root
            fi
            
            # Recreate it as a snapshot of the blank template
            btrfs subvolume snapshot /btrfs_tmp/root_blank /btrfs_tmp/root
            
            umount /btrfs_tmp
        '';
    };
}
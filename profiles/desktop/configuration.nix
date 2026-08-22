
{ config, lib, ... }:
{
  nixpkgs.hostPlatform = "x86_64-linux";

  myHardware = {
    nvidia = {
        enable = true;
        # Can also change to latest maybe on this machine.
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        open = true;
    };

    # Need to determine how I want to source device paths.
    disk = {
        main = {
            enable = true;
            device = lib.mkDefault "/dev/nvme0n1";
            ephemeral = true;
            swap = {
                enable = true;
                size = "16G";
            };
        };

        secondary = {
            enable = true;
            device = lib.mkDefault "/dev/sda";
        };
    };
  };
}

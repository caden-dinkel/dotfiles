
{ config, lib, ... }:
{
  nixpkgs.hostPlatform = "x86_64-linux";

  imports = [
    ../../modules/hardware/disko
    ../../modules/hardware/nvidia.nix
  ];

  myHardware = {
    nvidia = {
        enable = true;
        package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
        open = true;
    };

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

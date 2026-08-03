{ self, pkgs, config, lib, ... }:
{
  networking.hostName = "omen";

  imports = [
    "${self}/modules/base.nix"
    "${self}/modules/nvidia.nix"
    "${self}/modules/disko.nix"
    "${self}/modules/tailscale.nix"
    "${self}/modules/persist.nix"
    "${self}/modules/rollback.nix"

    "${self}/users/deploy.nix"
    "${self}/users/admin.nix"
    
    ./hardware-configuration.nix
  ];

  myHardware = {
    nvidia = {
        enable = true;
        package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
        prime = {
            enable = true;
            intelBusId = "PCI:0:2:0";
            nvidiaBusId = "PCI:1:0:0";
        };
    };
    disk = {
      mainDevice = "/dev/nvme0n1";
      enableSecondary = true;
      secondaryDevice = "/dev/sda";
      swapSize = "16G";
    };
  };

  nix.settings.trusted-users = [
    "root"
    "admin"
    "deploy"
  ];
}
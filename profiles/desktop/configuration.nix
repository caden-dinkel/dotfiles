
{ config, lib, ... }:
{
  nixpkgs.hostPlatform = "x86_64-linux";

  imports = [
    ../../hardware/disko
    ../../hardware/graphics/nvidia.nix
  ];

  myHardware = {
    nvidia = {
        enable = true;
        # Can also change to latest maybe on this machine.
        package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;
        open = true;
    };

    disk = {
      main = {
          enable = true;
          ephemeral = true;
          swap = {
              enable = true;
              size = "32G";
          };
      };
    };
  };
}

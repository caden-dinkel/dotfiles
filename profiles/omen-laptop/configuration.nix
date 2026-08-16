
    { self, pkgs, config, lib, ... }:
{
  nixpkgs.hostPlatform = "x86_64-linux";

  myHardware = {
    nvidia = {
        enable = true;
        package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
        prime.enable = false;
    };
    # Should consider looking for device-ids and whatnot to be more specific
    # And actually, this definition may partially need to be in hosts/<hostname>
    disk = {
      mainDevice = "/dev/nvme0n1";
      enableSecondary = true;
      secondaryDevice = "/dev/sda";
      swapSize = "16G";
    };
  };
  # May remove/move positions
  /*
  nix.settings.trusted-users = [
    "@wheel"
  ];
  */
}

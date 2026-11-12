# This device will be the binary cache.
{
  config,
  disko,
  ...
}:
{
  nixpkgs.hostPlatform = "x86_64-linux";

  time.timeZone = "America/Chicago";

  imports = [
    ../../modules/common.nix
    ../../modules/state-version.nix
    ../../modules/tailscale.nix
    ../../modules/deploy-user.nix
    ../../modules/server.nix
    disko.nixosModules.disko
    ./disko.nix
  ]
  ++ (
    let
      hardwareConfig = ./hardware-configuration.nix;
    in
    if builtins.pathExists hardwareConfig then [ hardwareConfig ] else [ ]
  );

  myNetworking.tailscale = {
    enable = true;
    profile = "server";
    authKeyFile = "/etc/tailscale/authkey";
  };

  myUsers.deploy = {
    enable = true;
    # Uses default ssh key.
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "charlie";

  hardware = {
    graphics.enable = true;
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
      modesetting.enable = true;
      open = true;
      powerManagement = {
        enable = true;
        finegrained = true;
      };
    };
  };

  boot.blacklistedKernelModules = [ "nouveau" ];
  
}

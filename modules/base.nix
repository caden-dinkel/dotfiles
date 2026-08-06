{ config, lib, self, ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "26.05";

  services.xserver.enable = false;

  services.journald.extraConfig = "Storage=persistent";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.configurationRevision = self.rev or self.dirtyRev or null;

  networking.useNetworkd = true;
  networking.wireless.iwd.enable = true;
  networking.useDHCP = false;
  systemd.network.enable = true;
  systemd.network.networks."10-wlan" = {
    matchConfig.Name = "wlan0";

    networkConfig = {
      DHCP = "ipv4";
    };
  };
  nixpkgs.config.allowUnfree = true;

}
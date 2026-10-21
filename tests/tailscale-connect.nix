{ pkgs, ... }:
pkgs.testers.runNixOSTest {
  name = "tailscale-connect";
  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/tailscale.nix
    ];

    myNetworking.tailscale = {
      enable = true;
      profile = "server";
      authKeyFile = "/etc/tailscale/authkey";
    };
  };
}
{ pkgs, ... }:
pkgs.testers.runNixOSTest {
  name = "tailscale-connect";
  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../modules/tailscale.nix
    ];

    # Need to come up with a method to get runtime secrets into this test vm.
    # The actual test is simple, just a hook checking for tailscale status.
    myNetworking.tailscale = {
      enable = true;
      profile = "server";
      authKeyFile = "/etc/tailscale/authkey";
    };
  };
}

{ lib, ... }: {
  imports = [ ../../modules/tailscale.nix ];
  myNetworking.tailscale = {
    enable = true;
    profile = "server";
    authKeyFile = lib.mkDefault "/etc/tailscale/authkey";
  };
}

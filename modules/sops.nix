{ name, pkgs, ... }:
let
  myHomeDir = if pkgs.stdenv.hostPlatform.isLinux then "/home/${name}" else "/Users/${name}";
in
{
  sops.defaultSopsFile = ../secrets/tailscale.yaml;
  # Key should be moved to root?
  sops.age.keyFile = myHomeDir + "/.config/sops/age/keys.txt";
  sops.age.generateKey = false;
  sops.secrets = {
    tailscaleClientId = {
      key = "tailscale/client_id";
    };
    tailscaleClientSecret = {
      key = "tailscale/client_secret";
    };
    "deploy-rs-key" = {
      sopsFile = ../secrets/deploy-rs-key;
      format = "binary";
    };
    /*
    "bin-cache-key" = {
      sopsFile = ../secrets/bin-cache-key;
      format = "binary";
    };
    */
  };
}

{ name, pkgs, ... }:
let
  myHomeDir = if pkgs.stdenv.hostPlatform.isLinux then "/home/${name}" else "/Users/${name}";
in
{
  sops.defaultSopsFile = ../secrets/tailscale.yaml;
  sops.age.keyFile = myHomeDir + ".config/sops/age/keys.txt";
  sops.secrets = {
    "tailscale/client_id" = { };
    "tailscale/client_secret" = { };
  };
}

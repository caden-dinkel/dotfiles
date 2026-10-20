{ nixos-anywhere, pkgs, self, ... }:
pkgs.writeShellApplication {
  name = "provision-new-machine";
  runtimeInputs = [
    pkgs.coreutils
    ${self.apps.get-tailscale-authkey}
  ];
  text = ''
    set -euo pipefail
    umask 077


    tempdir="$(mktemp -d)"
    trap 'rm -rf "$tempdir"' EXIT
    
  '';
}
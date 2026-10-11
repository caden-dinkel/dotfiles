{ pkgs, ... }:
let 
  keyname = "cache.domain-1"; # dummy for now, looking to automate.
in 
pkgs.writeShellApplication {
  name = "create-nix-cache-key";

  runtimeInputs = [
    pkgs.sops
    pkgs.openssh
    pkgs.coreutils
  ];
  text = ''
    set -euo pipefail
    umask 077

    repo_root="$(git rev-parse --show-toplevel)"
    encrypted_key="$repo_root/secrets/nix-cache-key"
    encrypted_filename="$encrypted_key"
    public_key="$repo_root/secrets/nix-cache-key.pub"

    tempdir="$(mktemp -d)"
    trap 'rm -rf "$tempdir"' EXIT

    private_key="$tempdir/nix-cache-key"
    
    nix-store --generate-binary-cache-key ${keyname} "$private_key" "$private_key.pub" \
      --quiet


    sops --encrypt \
      --filename-override "$encrypted_filename" \
      --input-type binary \
      --output-type binary \
      "$private_key" > "$encrypted_key"

    install -Dm0644 "$private_key.pub" "$public_key"
  '';
}

# Generate an ssh key and encrypt it with sops.
# Dependent on .sops.yaml setup.
{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "create-deploy-key";
  runtimeInputs = [
    pkgs.sops
    pkgs.openssh
    pkgs.coreutils
  ];
  text = ''
    set -euo pipefail
    umask 077

    repo_root="$(git rev-parse --show-toplevel)"
    encrypted_key="$repo_root/secrets/deploy-rs-key"
    public_key="$repo_root/secrets/deploy-rs-key.pub"

    tempdir="$(mktemp -d)"
    trap 'rm -rf "$tempdir"' EXIT

    private_key="$tempdir/deploy-rs-key"

    ssh-keygen \
      -q \
      -t ed25519 \
      -N "" \
      -C "deploy-rs" \
      -f "$private_key"

    sops encrypt \
      --input-type binary \
      --output-type binary \
      "$private_key" > "$encrypted_key"

    install -Dm0644 "$private_key.pub" "$public_key"
  '';
}

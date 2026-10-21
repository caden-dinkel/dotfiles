{
  nixos-anywhere,
  pkgs,
  self,
  system,
  ...
}:
pkgs.writeShellApplication {
  name = "provision-new-machine";
  runtimeInputs = [
    pkgs.coreutils
    self.packages.${system}.get-tailscale-authkey
    nixos-anywhere
    pkgs.nix
  ];
  # The ssh key here is dependent on the prior unkown setup.
  # There may not be an ssh key
  # However, in cases where a system already within the flake is being reprovisioned, it may be possible?
  # Could allow for some more impermanent setups.
  text = ''
    set -euo pipefail
    umask 077

    if [[ "$#" -ne 4 ]]; then
      echo "Usage: provision-new-machine <machine_name> <target_ip> <access_user> <path-to-private-key>" >&2
      exit 2
    fi

    machine_name="$1"
    target_ip="$2"
    access_user="$3"
    private_key="$4"

    repo_root="$(git rev-parse --show-toplevel)"

    tailscale_authkey_file="$(
    nix eval --raw \
    "$repo_root#nixosConfigurations.''${machine_name}.config.myNetworking.tailscale.authKeyFile"
    )"

    case "$tailscale_authkey_file" in
      /*) ;;
      *)
        echo "Expected an absolute Tailscale auth key path: $tailscale_authkey_file" >&2
        exit 1
        ;;
    esac

    tempdir="$(mktemp -d)"
    trap 'rm -rf "$tempdir"' EXIT

    mkdir -p "$tempdir$(dirname "$tailscale_authkey_file")"

    get-tailscale-authkey > "$tempdir$tailscale_authkey_file"

    nixos-anywhere \
    --generate-hardware-config nixos-generate-config "$repo_root/hosts/$machine_name/hardware-configuration.nix" \
    --flake "$repo_root#$machine_name" \
    --target-host "$access_user@$target_ip" \
    --extra-files "$tempdir" \
    -i "$private_key"
  '';
}

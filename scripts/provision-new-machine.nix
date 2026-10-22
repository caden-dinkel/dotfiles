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

  # Figure out way to pass --test conditionally to get-tailscale-authkey. Probably just another flag for now

  text = ''
    set -euo pipefail
    umask 077

    if [[ -v SSHPASS ]]; then
      echo "SSHPASS is present in the script environment"
    else
      echo "SSHPASS is missing from the script environment" >&2
    fi

    if [[ "$#" -ne 6 ]]; then
      echo "Usage: %s <machine_name> <target_ip> <access_user> <ts_client_id_file> <ts_client_secret_file> [--test]\n" "$0" >&2
      exit 2
    fi

    machine_name="$1"
    target_ip="$2"
    access_user="$3"
    ts_client_id_file="$4"
    ts_client_secret="$5"
    test=false

    if [[ $# -eq 6 ]]; then
      if [[ "$6" != "--test" ]]; then
        printf 'Error: Unknown argument: %s\n' "$3" >&2
        printf 'Usage: %s <client-id-file> <client-secret-file> [--test]\n' "$0" >&2
        exit 2
      fi
      test=true
    fi

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

    tst_var=""

    if test then
      tst_var="--test"
    fi

    get-tailscale-authkey "$ts_client_id_file" "$ts_client_secret" "$tst_var" > "$tempdir$tailscale_authkey_file"

    nixos-anywhere \
    --generate-hardware-config nixos-generate-config "$repo_root/hosts/$machine_name/hardware-configuration.nix" \
    --flake "$repo_root#$machine_name" \
    --target-host "$access_user@$target_ip" \
    --extra-files "$tempdir" \
    --env-password
  '';
}

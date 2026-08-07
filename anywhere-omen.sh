#!/bin/bash

set -euo pipefail

TARGET_IP=""
TAILSCALE_KEY=""
SOPS_PUB_KEY=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -target_ip) TARGET_IP="$1"; shift ;;
        -tailscale_auth_key) TAILSCALE_KEY="$1"; shift ;;
        -sops_pub_key) SOPS_PUB_KEY="$1"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    end
    shift
done

if [[ -z "$TARGET_IP" ]] || [[ -z "$TAILSCALE_KEY" ]]; then
    echo "Error: Missing required arguments."
    echo "Usage: $0 -target_ip <IP> -t_auth_key <KEY> -sops_pub_key <KEY> -sops_priv_key <KEY>"
    exit 1
fi

temp=$(mktemp -d)

cleanup() {
  rm -rf "$temp"
}

trap cleanup EXIT

install -d -m755 "$temp/etc/tailscale"

bw get password TAIL_SCALE_AUTH_SERVER --session "$BW_SESSION" \
  | install -m600 /dev/stdin "$temp/etc/tailscale/authkey"

nixos-anywhere --extra-files "$temp" --flake '.#omen' --target-host root@192.168.1.232 --generate-hardware-config nixos-generate-config ./hosts/omen/hardware-configuration.nix

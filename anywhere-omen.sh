#!/usr/bin/env bash

set -euo pipefail

set -a
source .env
set +a

temp=$(mktemp -d)

cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

install -d -m755 "$temp/etc/tailscale"

bw get password TAIL_SCALE_AUTH_SERVER --session "$BW_SESSION" \
  | install -m600 /dev/stdin "$temp/etc/tailscale/authkey"

nixos-anywhere --extra-files "$temp" --flake '.#omen' --target-host root@192.168.1.232 --generate-hardware-config nixos-generate-config ./hosts/omen/hardware-configuration.nix
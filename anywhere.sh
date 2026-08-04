temp=$(mktemp -d)

cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

install -d -m755 "$temp/etc/tailscale/authkey"

bw get password TAIL_SCALE_AUTH_SERVER > "$temp/etc/tailscale/authkey"

chmod 600 "$temp/etc/tailscale/authkey"

nixos-anywhere --extra-files "$temp" --flake '.#omen' --target-host root@192.168.1.232

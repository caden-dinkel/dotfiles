{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "create-tailscale-auth-key.nix";
  meta = {
    description = ''
      Script to get a temporary tailscale access key to modify auth keys.
      Input: Tailscale client ID, Tailscale client secret.
      Output: path to tmp file containing temporary access code.
    '';
  };
  runtimeInputs = [
    pkgs.curl
    pkgs.jq
  ];
  text = ''
    set -euo pipefail
    umask 077

    client_id="$(cat /run/secrets/tailscale/client_id)"
    client_secret="$(cat /run/secrets/tailscale/client_secret)"

    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT

    access_token="$tmpdir/tailscale_access_token"

    response=$(curl --fail --silent --show-error \
      --proto '=https' \
      --proto-redir '=https' \
      --max-redirs 0 \
      --connect-timeout 10 \
      --request POST \
      --header "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "grant_type=client_credentials" \
      --data-urlencode "client_id=''${client_id}" \
      --data-urlencode "client_secret=''${client_secret}" \
      "https://api.tailscale.com/api/v2/oauth/token"
    )

    jq -er '.access_token' <<<"$response" > "$access_token"

    printf '%s\n' "$access_token"
  '';
}
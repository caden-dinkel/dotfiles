{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "get-tailscale-authkey";
  runtimeInputs = [
    pkgs.curl
    pkgs.jq
  ];
  text = ''
    set -euo pipefail
    umask 077

    client_id="$(cat /run/secrets/tailscale/client_id)"
    client_secret="$(cat /run/secrets/tailscale/client_secret)"

    access_response="$(
      curl --fail --silent --show-error \
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
    )"

    access_token="$(jq -er '.access_token' <<<"$access_response")"

    get_authkey_response="$(
      curl --show-error \
        --proto '=https' \
        --proto-redir '=https' \
        --max-redirs 0 \
        --connect-timeout 100 \
        --request POST \
        --header 'Content-Type: application/json' \
        --header "Authorization: Bearer $access_token" \
        --data '{
          "keyType": "auth",
          "description": "Provision new machine",
          "capabilities": {
            "devices": {
              "create": {
                "reusable": true,
                "ephemeral": false,
                "preauthorized": true,
                "tags": [
                  "tag:provisioned-machine"
                ]
              }
            }
          },
          "expirySeconds": 600
        }' \
        "https://api.tailscale.com/api/v2/tailnet/-/keys"
    )"

    authkey="$(jq -er '.key' <<<"$get_authkey_response")"

    echo "$authkey"
  '';

}

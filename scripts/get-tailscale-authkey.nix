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

      if [[ $# -lt 2 || $# -gt 3 ]]; then
        printf 'Usage: %s <client-id-file> <client-secret-file> [--test]\n' "$0" >&2
        exit 2
      fi

      client_id_file="$1"
      client_secret_file="$2"
      test="false"

      if [[ $# -eq 3 ]]; then
        if [[ "$3" != "--test" ]]; then
          printf 'Error: Unknown argument: %s\n' "$3" >&2
          printf 'Usage: %s <client-id-file> <client-secret-file> [--test]\n' "$0" >&2
          exit 2
        fi
        test="true"
      fi


      client_id="$(cat "$client_id_file")"
      client_secret="$(cat "$client_secret_file")"

      if ! access_response="$(
        curl --fail-with-body --silent --show-error \
          --proto '=https' \
          --proto-redir '=https' \
          --max-redirs 0 \
          --connect-timeout 10 \
          --request POST \
          --header "Content-Type: application/x-www-form-urlencoded" \
          --data-urlencode "grant_type=client_credentials" \
          --data-urlencode "client_id=''${client_id}" \
          --data-urlencode "client_secret=''${client_secret}" \
          --data-urlencode "scope=auth_keys" \
          --data-urlencode "" \
          "https://api.tailscale.com/api/v2/oauth/token"
      )"; then
        printf '%s\n' 'Tailscale access token request failed.' >&2
        exit 1
      fi

      if ! access_token="$(jq -er '.access_token' <<<"$access_response")"; then
        printf '%s\n' 'Tailscale response did not contain an access token.' >&2
        exit 1
      fi

      content=$(cat << EOF
      {
            "keyType": "auth",
            "description": "Provision new machine",
            "capabilities": {
              "devices": {
                "create": {
                  "reusable": true,
                  "ephemeral": $test,
                  "preauthorized": true,
                  "tags": [
                    "tag:provisioned-machine"
                  ]
                }
              }
            },
            "expirySeconds": 600
          }
    EOF
      )

      if ! get_auth_key_response="$(
        curl --fail-with-body --silent --show-error \
          --proto '=https' \
          --proto-redir '=https' \
          --max-redirs 0 \
          --connect-timeout 100 \
          --request POST \
          --header 'Content-Type: application/json' \
          --header "Authorization: Bearer $access_token" \
          --data "$content" \
          "https://api.tailscale.com/api/v2/tailnet/-/keys"
      )"; then
        echo "Tailscale auth key request failed."
        exit 1
      fi

      if ! auth_key="$(jq -er '.key' <<<"$get_auth_key_response")"; then
        printf '%s\n' 'Tailscale response did not contain an auth key.' >&2
        exit 1
      fi

      printf '%s\n' "$get_auth_key_response"

      printf '%s\n' "$auth_key"
  '';
}

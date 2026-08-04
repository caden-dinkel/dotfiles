{ config, nixpkgs, ... }:
{
    services.tailscale = {
        enable = true;
        authKeyFile = ""; # Passed with nixos-anywhere hopefully (need to figure out).
        extraUpFlags = [ "--hostname=${config.networking.hostName}" ];
    };

    systemd.services.tailscale = {
        after = [ "network-online.target" "firewall.service" ];
        wants = [ "network-online.target" ];
    
        serviceConfig = {
            Restart = nixpkgs.lib.mkForce "on-failure";
            RestartSec = "5s";
        };
    };
}
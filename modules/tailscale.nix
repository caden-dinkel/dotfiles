{ config, lib, pkgs, ... }:
{
    services.tailscale = {
        enable = true;
        authKeyFile = "/etc/tailscale/authkey"; # Passed with nixos-anywhere hopefully (need to figure out).
        extraUpFlags = [ "--hostname=${config.networking.hostName}" ];
    };

    systemd.services.tailscale = {
        description = "Retry tailscale daemon.";
        after = [ "network-online.target" "firewall.service" ];
        wants = [ "network-online.target" ];
    
        serviceConfig = {
            Restart = lib.mkForce "on-failure";
            RestartSec = "5s";
        };
    };

    systemd.services.remove-tailscale-authkey = {
        description = "Remove Tailscale auth key after registration";
        wantedBy = [ "multi-user.target" ];
        after = [ "tailscale.service" ];
        requires = [ "tailscale.service" ];
        serviceConfig = {
            Type = "oneshot";
            ExecStart = "${lib.getExe' pkgs.coreutils "rm"} -f /etc/tailscale/authkey";
        };
    };

    networking.firewall = {
        trustedInterfaces = [ "tailscale0" ];
        allowedUDPPorts = [ config.services.tailscale.port ];
    };
}
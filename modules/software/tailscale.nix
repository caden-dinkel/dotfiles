# Explicit module for server roles.
{ config, lib, pkgs, ... }:
let
    keyPath = "/etc/tailscale/authkey";
in
{
    services.tailscale = {
        enable = true;
        authKeyFile = keyPath;
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

    # We need to leave the file there, so that the system activation script can see it.
    systemd.services.remove-tailscale-authkey = {
        description = "Remove Tailscale auth key after registration";
        wantedBy = [ "multi-user.target" ];
        after = [ "tailscaled-autoconnect.service" ];
        requires = [ "tailscale.service" ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
        };
        script = ''
            (: > ${keyPath})
        '';
    };

    networking.firewall = {
        trustedInterfaces = [ "tailscale0" ];
        allowedUDPPorts = [ config.services.tailscale.port ];
    };
}
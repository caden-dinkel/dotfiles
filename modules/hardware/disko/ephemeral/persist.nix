{ config, lib, ... }:
let
  cfg = config.myHardware.disk;
in
{
    config = lib.mkIf (cfg.main.enable && cfg.main.ephemeral) {
        environment.persistence."/persist" = {
            enable = true;
            hideMounts = true;
            directories = [
                "/var/lib/tailscale"
                "/var/lib/nixos"
                "/etc/ssh"
                "/etc/NetworkManager/system-connections"
                "/var/log"
            ];
            files = [
                "/etc/machine-id"
            ];
        };
        fileSystems = {
            "/persist".neededForBoot = true;
        };
    };
}
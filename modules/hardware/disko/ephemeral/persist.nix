{ config, lib, ... }:
let
  cfg = config.myHardware.disk;
  tailscaleKeyPath = config.services.tailscale.authKeyFile;
in
{
    config = lib.mkIf (cfg.main.enable && cfg.main.ephemeral) {
        environment.persistence."/persist" = {
            enable = true;
            hideMounts = true;
            directories = [
                tailscaleKeyPath # This path should be referenced from modules/software/tailscale.nix
                "/var/lib/nixos"
                "/etc/ssh"
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
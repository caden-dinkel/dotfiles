{ lib, pkgs, ... }:
{
    config = lib.mkIf pkgs.stdenv.isLinux {
        # This may want to be pushed up the graph (become less of a dependency)
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        system.stateVersion = "26.05";

        networking.nameservers = [
            "1.1.1.1"
            "1.0.0.1"
            "8.8.8.8"
            "8.8.4.4"
        ];

        systemd.network.enable = true;

        networking.useDHCP = false;

        systemd.network.networks."10-ethernet-default" = {
            matchConfig.Name = "en* eth*";

            networkConfig = {
                DHCP = "yes";
            };
        };
    };
}

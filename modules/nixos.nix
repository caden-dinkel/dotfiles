{ lib, pkgs, ... }:
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    services.openssh = {
        enable = true;
        ports = [ 2222 ];
        settings = {
            PasswordAuthentication = false;
            PermitRootLogin = "no";
        };
    };

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    system.stateVersion = "26.05";

    networking.nameservers = [
        "1.1.1.1" # Cloudflare
        "1.0.0.1" # Cloudflare backup
        "8.8.8.8" # Google
        "8.8.4.4" # Google backup
    ];

    systemd.network.enable = true;

    networking.useDHCP = false;

    systemd.network.networks."10-ethernet-default" = {
        matchConfig.Name = "en* eth*";

        networkConfig = {
            DHCP = "yes";
        };
    };
}
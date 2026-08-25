{ lib, pkgs, self, ... }:
{
config = lib.mkMerge [
{
    environment.systemPackages = [
        pkgs.age
        pkgs.git
    ];
    # This can probably be moved to the top level of flake.
    system.configurationRevision = self.rev or self.dirtyRev or null;
    nix.settings.experimental-features = "nix-command flakes";
    nixpkgs.config.allowUnfree = true;
    
    services.tailscale.enable = true;
}
(lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
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
})
(lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    environment.systemPackages = [
        pkgs.vfkit
    ];
    nix.settings.trusted-users = [
        "@admin"
    ];
    system.stateVersion = 6;
    system.defaults = {
        finder = {
            AppleShowAllFiles = true;
            AppleShowAllExtensions = true;
        };
        NSGlobalDomain = {
            AppleShowAllFiles = true;
            _HIHideMenuBar = true;
        };
        dock.autohide = true;
    };
    networking.dns = [
        "1.1.1.1" # Cloudflare
        "1.0.0.1" # Cloudflare backup
        "8.8.8.8" # Google
        "8.8.4.4" # Google backup
    ];
})
];
}
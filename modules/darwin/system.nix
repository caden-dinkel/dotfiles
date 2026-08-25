{ lib, pkgs, ... }:
{
    config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        # May move this out of here and into personal role for darwin if it shouldn't be on servers
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

        # Annoying that these are separate between darwin and nixos.
        networking.dns = [
            "1.1.1.1"
            "1.0.0.1"
            "8.8.8.8"
            "8.8.4.4"
        ];
    };
}

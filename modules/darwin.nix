{
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
}
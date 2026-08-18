{
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
}
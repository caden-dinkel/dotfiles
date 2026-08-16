{
    # May move this out of here and into personal role for darwin if it shouldn't be on servers
    nix.settings.trusted-users = [
        "@admin"
    ];

    system.stateVersion = 6;
}
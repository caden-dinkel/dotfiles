{
    nix.linux-builder = {
        enable = true;
        package = pkgs.darwin.linux-builder-vz;
        systems = [
            "aarch64-linux"
            "x86_64-linux" 
        ];

        ephemeral = true;
        maxJobs = 4;
        config = {
            virtualisation = {
                darwin-builder = {
                    diskSize = 40 * 1024;
                    memorySize = 8 * 1024;
                };
                cores = 6;
            };
        };
    };
    # nix.settings.trusted-users = [ "@admin" ]; is set in modules/darwin/system.nix
}
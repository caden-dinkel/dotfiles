{ self, ... }:
{
    nix.settings.experimental-features = "nix-command flakes";

    # Whether or not to utilize machines listed in `nix.buildMachines` for builds.
    # Should be enabled once build servers are up.
    # nix.distributedBuilds = true;

    nixpkgs.config.allowUnfree = true;

    networking.dns = [

    ];

    # Overall flake hash/revision
    system.configurationRevision = self.rev or self.dirtyRev or null;

    # Will likely want to configure in the future
    # system.checks = [];
}
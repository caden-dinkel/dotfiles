{ pkgs, self, lib, ... }:
{
    environment.systemPackages = [
        pkgs.age
        pkgs.git
    ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        pkgs.vfkit
    ];

    system.configurationRevision = self.rev or self.dirtyRev or null;

    nix.settings.experimental-features = "nix-command flakes";

    nixpkgs.config.allowUnfree = true;
    
    services.tailscale.enable = true;
}
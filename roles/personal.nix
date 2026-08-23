{ self, pkgs, ... }:
{
    # cdink user pulls in the home-manager profile.
    imports = [
        "${self}/users/cdink.nix"
        "${self}/modules"
        "${self}/modules/desktop"
    ];
}
{ self, pkgs, ... }:
{
    # the cdink user should probably pull in the home directly in the user to be pulled here.
    imports = [
        "${self}/users/cdink.nix"
        "${self}/modules"
        "${self}/modules/desktop"
    ];
}
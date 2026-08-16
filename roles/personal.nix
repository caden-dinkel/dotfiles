{ self, pkgs, ... }:
let
    homeUser = "cdink";
in
{
    # the cdink user should probably pull in the home directly in the user to be pulled here.
    imports = [
        "${self}/users/cdink.nix"
        "${self}/modules"
        "${self}/modules/home"

        {
            _module.args = { inherit homeUser; };
        }
    ];

    fonts.packages = [
        pkgs.nerd-fonts.fira-code
        pkgs.nerd-fonts.fira-mono
        pkgs.nerd-fonts.hack
    ];
    
}
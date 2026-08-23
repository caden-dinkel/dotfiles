{ self, ... }:
{
    imports = [
        "${self}/users"
        "${self}/modules"
        "${self}/modules/software/tailscale.nix"
    ];
    services.xserver.enable = false;
}
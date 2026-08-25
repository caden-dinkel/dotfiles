{ self, ... }:
{
    imports = [
        ../modules
        ../modules/software/tailscale.nix
        ../users
    ];
    services.xserver.enable = false;

}
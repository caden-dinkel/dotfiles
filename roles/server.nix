{ self, ... }:
{
    imports = [
        ../modules/common
        ../modules/software/tailscale.nix
        ../users
    ];
    services.xserver.enable = false;
}
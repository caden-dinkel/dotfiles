{ self, ... }:
{
    networking.hostName = "charlie";
    imports = [
        ../../profiles/omen-laptop
        ../../roles/server.nix
        ./hardware-configuration.nix
    ];
}
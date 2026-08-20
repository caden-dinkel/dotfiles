{ self, ... }:
{
    networking.hostName = "charlie";
    imports = [
        "${self}/profiles/omen-laptop"
        "${self}/roles/server.nix"
        ./hardware-configuration.nix
    ];
}
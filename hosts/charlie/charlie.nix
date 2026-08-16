{ self, ... }:
{
    networking.hostName = "charlie";
    imports = [
        "${self}/profiles/omen-laptop"
        "${self}/modules/roles/server"
        ./hardware-configuration.nix
    ];
}
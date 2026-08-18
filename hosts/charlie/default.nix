{ self, ... }:
{
    networking.hostName = "charlie";
    imports = [
        "${self}/profiles/omen-laptop"
        "${self}/roles/server.nix"
        "${self}/metadata/nixos-x86_64.nix"
        ./hardware-configuration.nix
    ];
}
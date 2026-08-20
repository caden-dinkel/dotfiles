{ self, ... }:
{
    networking.hostName = "bravo";
    imports = [
        "${self}/profiles/desktop"
        "${self}/roles/personal.nix"
        ./hardware-configuration.nix
    ];
}
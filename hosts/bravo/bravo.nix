{ self, ... }:
{
    networking.hostName = "bravo";
    imports = [
        "${self}/profiles/desktop"
        "${self}/modules/roles/personal"
        ./hardware-configuration.nix
    ];
}
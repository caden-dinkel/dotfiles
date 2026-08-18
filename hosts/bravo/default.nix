{ self, ... }:
{
    networking.hostName = "bravo";
    imports = [
        "${self}/profiles/desktop"
        "${self}/roles/personal.nix"
        "${self}/metadata/linux-x86_64.nix"
        ./hardware-configuration.nix
    ];
}
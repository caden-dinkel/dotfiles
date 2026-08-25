{ self, ... }:
{
    networking.hostName = "bravo";
    imports = [
        ../../profiles/desktop
        ../../roles/personal.nix
        ./hardware-configuration.nix
    ];
}
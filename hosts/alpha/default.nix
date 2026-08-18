{ self, ... }:
{
    networking.hostName = "alpha";
    imports = [
        "${self}/profiles/darwin"
        "${self}/roles/personal.nix"
    ];
}
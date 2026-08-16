{ self, ... }:
{
    networking.hostName = "alpha";
    imports = [
        "${self}/profiles/darwin"
        "${self}/modules/roles/personal"
    ];
}
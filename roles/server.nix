{ self, ... }:
{
    imports = [
        "${self}/users"
        "${self}/modules"
    ];
    services.xserver.enable = false;
}
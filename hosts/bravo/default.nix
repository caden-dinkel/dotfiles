{ self, ... }:
{
    _module.args = {
        platform = "nixos";
    };
    networking.hostName = "bravo";
    imports = [
        ../../desktop
    ];
}
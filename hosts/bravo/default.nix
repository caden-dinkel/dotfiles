{ self, ... }:
{
    _module.args = {
        userName = "cdink";
        userDescription = "Caden Dinkel";
        platform = "nixos";
    };
    networking.hostName = "bravo";
    imports = [
        ../../desktop
    ];
}
{
    _module.args = {
        platform = "nixos";
    };
    networking.hostName = "charlie";
    imports = [
        ./hardware-configuration.nix
        ../../profiles/omen-laptop
    ];
}
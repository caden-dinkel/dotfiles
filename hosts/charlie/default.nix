{
    _module.args = {
        platform = "nixos";
    };
    networking.hostName = "charlie";
    imports = [
        ../../profiles/omen-laptop
    ];
}
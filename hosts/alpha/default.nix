{
    _module.args = {
        platform = "darwin";
    };
    networking.hostName = "alpha";
    imports = [
        ../../profiles/apple-silicon
    ];
}
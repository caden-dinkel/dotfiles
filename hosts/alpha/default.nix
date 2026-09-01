{
    _module.args = {
        userName = "cdink";
        userDescription = "Caden Dinkel";
        platform = "darwin";
    };
    networking.hostName = "alpha";
    imports = [
        ../../profiles/apple-silicon
    ];
}
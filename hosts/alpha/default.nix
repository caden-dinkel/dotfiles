let
    rootPath = ../..;
in
{
    _module.args = {
        platform = "darwin";
    };
    networking.hostName = "alpha";
    imports = [
        "${rootPath}/profiles/apple-silicon"
        "${rootPath}/roles"
    ];
}
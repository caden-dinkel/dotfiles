let
    rootPath = ../..;
in
{
    _module.args = {
        platform = "nixos";
    };
    networking.hostName = "bravo";
    imports = [
        ./hardware-configuration.nix
        "${rootPath}/profiles/desktop"
        "${rootPath}/roles/default.nix"
    ];
}
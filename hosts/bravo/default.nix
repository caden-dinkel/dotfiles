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
        "${rootPath}/modules/users/user.nix"
        "${rootPath}/roles/default.nix"
    ];
    myUsers = {
        me = {
            enable = true;
            description = "me";
        };
    };
}
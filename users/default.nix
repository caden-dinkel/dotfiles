{ config, lib, pkgs, ... }:
# inject global UID into users defined in ./registry.nix
let
    registry = import ./registry.nix;
    mkUser = userName: userModule: {
        imports = [ userModule ];
        users.users.${userName}.uid = registry.${userName};
    };
in
{
    imports = [
        ( mkUser "admin" ./admin.nix )
        ( mkUser "deploy" ./deploy.nix )
    ];
}
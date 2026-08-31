{ config, lib, pkgs, ... }:
let 
    cfg = config.mySystem;
    rolesPath = ./;

    # consider further limiting this to directories with a default.nix file.
    availableRoles = lib.attrNames (
      lib.filterAttrs (n: v: v == "directory") (builtins.readDir rolesPath)
    );
in
{
    options.mySystem = {
        roles = mkOption {
            type = lib.types.listOf (lib.types.enum availableRoles);
            default = [];
            description = "List of active system roles derived from the roles directory.";
        };
    };

    config = {
        imports = map (role: rolesPath + "/${role}") cfg.roles;
    };
}
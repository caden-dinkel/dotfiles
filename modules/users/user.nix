{ config, lib, pkgs, ... }:

let
  cfg = config.myUsers;
in
{
  options.myUsers = lib.mkOption {
    default = {};
    description = "Definition of multiple user accounts.";
    type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
      options = {
        enable = lib.mkEnableOption "Enable this user account.";
        
        description = lib.mkOption {
          type = lib.types.str;
          default = "default account";
          description = "The description for the user account.";
        };

        template = lib.mkOption {
          type = lib.types.enum [ "default-user" ];
          default = "default-user";
          description = "The user template to work from under ./users/";
        };

        extraArgs = lib.mkOption {
          type = lib.types.attrs;
          default = {};
          description = "Additional attribute set to declare for user.";
        };
      };
    }));
  };

# Go through this more carefully.
  config = lib.mkMerge (
    lib.mapAttrsToList (userName: userCfg:
      lib.mkIf userCfg.enable (lib.mkMerge [
        {
          users.users."${userName}" = {
            name = userName;
            description = userCfg.description;
          };
        }
        userCfg.extraArgs
        (import ./"${userCfg.template}.nix")
      ])
    ) cfg
  );
}
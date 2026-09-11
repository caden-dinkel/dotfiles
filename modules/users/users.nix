{ config, lib, ... }:
let
    cfg = config.myUsers.users;

    userOpts = { name, config, ... }:
    {
        options = {
            enable = mkOption {
                type = types.bool;
                default = true;
                example = false;
                description = ''
                    If set to false, the user account will not be created. 
                    This is useful for when you wish to conditionally
                    disable user accounts.
                '';
            };

            
        };
    };
{
    # See if you can expand the users.users.<name> namespace with a template arguement.
    # Look at source code for nixpkgs/nixos/modules/config/users-groups.nix for inspo.
}
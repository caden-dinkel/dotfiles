{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myUsers.deploy;
  deployPubKeyPath = ../secrets/deploy-rs-key.pub;
in
{
  options.myUsers.deploy = {
    enable = lib.mkEnableOption "Enable the user for deploy-rs.";
    sshKeyFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [
        deployPubKeyPath
      ];
      description = ''
        Paths to ssh keys to add to deploy user's authorized keys.
      '';
      example = [
        ../secrets/sshkey.pub
      ];
    };
  };
  config = lib.mkIf cfg.enable {
    users.groups.deploy = { };
    users.users.deploy = {
      description = "Deployment user for deploy-rs.";
      openssh.authorizedKeys.keyFiles = cfg.sshKeyFiles;
    }
    // lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      isNormalUser = true;
      group = "deploy";
    };
    # Restricts networking for ssh-ing into deploy user to tailscale interfaces.
    # Add an option to pull this from (maybe a myssh.ipRange)?
    # Temporary comment until machine is connected.
    /*
      services.openssh = {
        extraConfig = ''
          Match Address 100.64.0.0/10
            AllowUsers deploy
          Match all
            DenyUsers deploy
        '';
      };
    */

    # Temporary until specific commands are known.
    security.sudo = {
      enable = true;
    }
    // lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      extraRules = [
        {
          users = [ "deploy" ];
          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
    }
    // lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      extraConfig = ''

      '';
    };
  };
}

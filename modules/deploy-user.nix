{
  config,
  lib,
  pkgs,
  deployPubKey,
  ...
}:
let
  cfg = config.myUsers.deploy;
in
{
  options.myUsers.deploy = {
    enable = lib.mkEnableOption "Enable the user for deploy-rs.";
    sshKeys = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      default = [
        deployPubKey
      ];
      description = ''
        ssh keys to add to deploy user's authorized keys.
      '';
      example = [
        "ssh-rsa AAAAB3NzaC1yc2etc/etc/etcjwrsh8e596z6J0l7 example@host"
        "ssh-ed25519 AAAAC3NzaCetcetera/etceteraJZMfk3QPfQ foo@bar"
      ];
    };
  };
  config = lib.mkIf cfg.enable {
    users.groups.deploy = { };
    users.users.deploy = {
      description = "Deployment user for deploy-rs.";
      group = "deploy";
      openssh.authorizedKeys.keys = cfg.sshKeys;
    };
    # Restricts networking for ssh-ing into deploy user to tailscale interfaces.
    # Add an option to pull this from. (maybe a myssh.interface)
    services.openssh = {
      extraConfig = ''
        Match Address 100.64.0.0/10
          AllowUsers deploy
        Match all
          DenyUsers deploy
      '';
    };
  };
}

/*
  users.groups.deploy = { };
  users.users.deploy = {
    description = "Deployment User for deploy-rs";
    group = "deploy";
    createHome = false;
    openssh.authorizedKeys.keys = [

    ];
  };
*/

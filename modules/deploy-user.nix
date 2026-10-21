{
  config,
  lib,
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
      group = "deploy";
      openssh.authorizedKeys.keyFiles = cfg.sshKeyFiles;
      isNormalUser = true;
    };
    # Restricts networking for ssh-ing into deploy user to tailscale interfaces.
    # Add an option to pull this from (maybe a myssh.ipRange)?
    services.openssh = {
      extraConfig = ''
        Match Address 100.64.0.0/10
          AllowUsers deploy
        Match all
          DenyUsers deploy
      '';
    };

    # Temporary until specific commands are known.
    security.sudo.enable = true;
    security.sudo.extraRules = [
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
  };
}

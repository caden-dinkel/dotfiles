{ pkgs, ... }:
{
    users.users.deploy = {
        description = "Deployment User for deploy-rs";
        group = "deploy";
        # Check whether deploy-rs/SSH need a home dir. 
        createHome = false;
        isSystemUser = true;
        openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPQSQpXpm7lmsfqUnyUzRD+h3CkXVlxPKyhMOSxAa7ml mac@cdink.dev"
        ];
    };

    users.groups.deploy = {};

    security.sudo = {
        enable = true;
        extraRules = [
        {
            users = [ "deploy" ];
            commands = [
            {
                command = "/nix/store/*-nixos-system-*/bin/switch-to-configuration switch";
                options = [ "NOPASSWD" ];
            }
            {
                command = "/run/current-system/sw/bin/nix-env";
                options = [ "NOPASSWD" ];
            }
            ];
        }
      ];
  };
}
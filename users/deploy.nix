{ pkgs }:
{
    users.users.deploy = {
        isNormalUser = true;
        description = "Deployment User for deploy-rs";
        openssh.authorizedKeys.keys = [
            ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPQSQpXpm7lmsfqUnyUzRD+h3CkXVlxPKyhMOSxAa7ml mac@cdink.dev
        ];
    };

    security.sudo = {
        enable = true;
        extraRules = [
        {
            users = [ "deploy" ];
            commands = [
            {
                # Allow switching to the newly deployed system profile
                command = "/nix/store/*-nixos-system-*/bin/switch-to-configuration";
                options = [ "NOPASSWD" ];
            }
            {
                # Allow manipulating the system profile symlink
                command = "${pkgs.nix}/bin/nix-env";
                options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
  };
}
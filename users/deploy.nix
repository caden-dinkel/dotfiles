{ pkgs, ... }:
{
    users.users.deploy = {
        description = "Deployment User for deploy-rs";
        group = "deploy";
        # SSH requires a home-dir.
        createHome = true;
        home = "/var/lib/deploy";
        shell = pkgs.bashInteractive; 
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




# Found on Reddit. Might be decent, but it's a year old.
/*
  security.sudo.extraRules = [
    {
      groups = ["deploy"];
      commands = [
        {
          command = "/run/current-system/sw/bin/systemd-run";
          options = ["NOPASSWD"];
        }
        {
          command = "/nix/store/*/bin/switch-to-configuration";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/nix-store";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/nix-env";
          options = ["NOPASSWD"];
        }
        {
          command = ''/bin/sh -c "readlink -e /nix/var/nix/profiles/system || readlink -e /run/current-system"'';
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/nix-collect-garbage";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
*/
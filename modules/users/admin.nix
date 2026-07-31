{ pkgs }:

{
    users.users.admin = {
        isNormalUser = true;
        description = "Deployment User for deploy-rs";
        extraGroups = [ 
            "trusted-users"
            "wheel"
        ];
        openssh.authorizedKeys.keys = [
            ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPQSQpXpm7lmsfqUnyUzRD+h3CkXVlxPKyhMOSxAa7ml mac@cdink.dev
        ];
        
    };
    nix.settings.trusted-users = [ "admin" ];
}
{
    users.users.admin = {
        isNormalUser = true;
        description = "Emergency User for servers.";
        extraGroups = [ 
            "wheel"
        ];

        openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPQSQpXpm7lmsfqUnyUzRD+h3CkXVlxPKyhMOSxAa7ml mac@cdink.dev"
        ]; 
    };

    security.sudo.extraRules = [
        {
            users = [ "admin" ];
            commands = [
                {
                    command = "ALL";
                    options = [ "NOPASSWD" ];
                }
            ];
        }
    ];
}
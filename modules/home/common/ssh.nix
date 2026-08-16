{ pkgs, ... }:
{
    programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
            "github.com" = {
                HostName = "github.com";
                User = "git";
                # Need to figure something out for my personal machine user accounts.
                # I may either try to unify their user account in this flake (preferred), or just properly filter based on the system.
                # Or this may actually be good enough.
                # I would think this would be good, as home-manager's are declared per user.
                IdentityFile = "~/.ssh/git_id_ed25519"; 
            };
        };
    };
}
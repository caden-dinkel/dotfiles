{ pkgs, ... }:
{
    programs.ssh = {
        enable = true;
        settings = {
            "github.com" = {
                HostName = "github.com";
                User = "git";
                IdentityFile = "~/.ssh/git_id_ed25519";
            };
        };
    };
}
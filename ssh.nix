{ pkgs, ... }:
{
    programs.ssh = {
        enable = true;
        
        matchBlocks = {
            github = {
                host = "github.com";
                user = "git";
                identityFile = "~/.ssh/git_id_ed25519";
                identitiesOnly = true;
            };
        };
    };
}
{ pkgs, ... }:
{
    programs.git = {
        enable = true;
        package = pkgs.git;
        ignores = [ "**/.DS_STORE" ];
        signing = {
            key = null;
            format = "ssh";
            signByDefault = true;
        };
        settings = {
            user = {
                name = "Caden Dinkel";
                email = "git@cdink.dev";
            };
            core.sshCommand = "ssh";
            github.user = "caden-dinkel";
            init.defaultBranch = "main";
        };
    };
}
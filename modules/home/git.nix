{ pkgs, ... }:
{
    programs.git = {
        enable = true;
        ignores = [ "**/.DS_STORE" ];
        settings = {
            user = {
                name = "Caden Dinkel";
                email = "git@cdink.dev";
            };
            github.user = "caden-dinkel";
            init.defaultBranch = "main";
        };
    };
}
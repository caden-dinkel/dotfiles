{
    programs.git = {
        enable = true;
        ignores = [ "**/.DS_Store" ];
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
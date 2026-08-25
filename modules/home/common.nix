{ git, ... }:
{
    programs.git = {
        enable = true;
        ignores = [ "**/.DS_Store" ];
        settings = {
            user = {
                name = git.name;
                email = git.email;
            };
            github.user = git.username;
            init.defaultBranch = "main";
        };
    };
    programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
            "github.com" = {
                HostName = "github.com";
                User = "git";
                IdentityFile = git.id; 
            };
        };
    };
}
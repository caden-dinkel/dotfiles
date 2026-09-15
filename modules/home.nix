{ name, pkgs, ... }
{
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${name} = {
        home.packages = [
            pkgs.tree
            pkgs.tmux
            pkgs.ripgrep
        ];
        programs.git = {
            enable = true;
            ignores = [ "**/.DS_Store" ];
            settings = {
                user = {
                    name = git.name;
                    email = git.email;
                };
                init.defaultBranch = "main";
                push.autoSetupRemote = true;
            };
        };
        programs.ssh = {
            enable = true;
            settings = {
                "github.com" = {
                    HostName = "github.com";
                    User = "git";
                    IdentityFile = "~/.ssh/id_ed25519_github";
                    IdentitiesOnly = true;
                };
            };
        };
        programs.vscode = {
            enable = true;
        };
        programs.alacritty = {
            enable = true;
        };
        programs.claude-code = {
            enable = true;
        };
        programs.ncspot = {
            enable = true;
        };
        programs.obsidian = {
            enable = true;
        };
    };
}
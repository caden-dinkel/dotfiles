{ name, pkgs, git, ... }:
{
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${name} = {
        home.packages = [
            pkgs.tree
            pkgs.tmux
            pkgs.ripgrep
            pkgs.bitwarden-desktop
        ];
        home.homeDirectory = if pkgs.stdenv.hostPlatform.isLinux then "/home/${name}" else "/Users/${name}";
        home.stateVersion = "26.05";
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
            enableDefaultConfig = false;
            settings = {
                "github.com" = {
                    HostName = "github.com";
                    User = "git";
                    IdentityFile = "~/.ssh/git_id_ed25519";
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
        programs.firefox = {
            enable = true;
        };
    };
}
{ username, lib, pkgs, git, ... }:
{
    home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
    };

    users."${username}" = lib.mkMerge [
    {
        home = {
            stateVersion = "26.05";
            packages = [
                pkgs.bitwarden-cli
                pkgs.tree
                pkgs.tmux
            ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                pkgs.xdg-utils
            ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
                pkgs.maccy
                pkgs.tailscale-gui
            ];
        };

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
    } (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        programs.hyprland = {
            enable = true;
        };
        programs.fuzzel = {
            enable = true;
        };
        programs.waybar = {
            enable = true;
        };
        programs.hyprlock = {
            enable = true;
        };

        services.mako = {
            enable = true;
        };
        services.awww = {
            enable = true;
        };
        services.hypridle = {
            enable = true;
        };
        services.cliphist = {
            enable = true;
        };
    })
    (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        services.skhd = {
            enable = true;
        };
    })
    ];
}
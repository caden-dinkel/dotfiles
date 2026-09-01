{ userName, pkgs, ... }:
{
    home-manager.users."${userName}" = {
        home.packages = [
            pkgs.tree
            pkgs.tmux
        ];
    };
}
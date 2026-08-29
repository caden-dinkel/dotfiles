{ pkgs, ... }:
{
    home.packages = [
        pkgs.tree
        pkgs.tmux
    ];
}
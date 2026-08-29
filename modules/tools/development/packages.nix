{ pkgs, ... }:
{
    environment.systemPackages = [
        pkgs.tree
        pkgs.tmux
    ];
}
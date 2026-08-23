{ pkgs, ... }:
{
    home.packages = [
        pkgs.maccy
        pkgs.tailscale-gui
    ];
}
{ pkgs, ... }:
{
    environment.systemPackages = [
        pkgs.xdg-utils
    ];
    xdg.portal.extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
    ];
}
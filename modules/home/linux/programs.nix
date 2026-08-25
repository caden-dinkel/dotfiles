{ lib, pkgs, ... }:
{
    config = lib.mkIf pkgs.stdenv.isLinux {
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
    };
}

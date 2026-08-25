{ lib, pkgs, ... }:
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
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
}
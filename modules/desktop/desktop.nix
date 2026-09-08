{ config, lib, pkgs, ... }:
let
    cfg = config.modules.desktop;

    
    # Checks based on pkgs.stdenv.hostPlatform.isDarwin/isLinux



    desktopModules = {
        darwin = {
            yabai = ./yabai;
        };
        nixos = {
            gnome = ./gnome
            kde = ./kde;
            hyprland = ./hyprland;
        };
    };

    availableModules = if pkgs.stdenv.hostPlatform.isLinux 
    then desktopModules.nixos 
    else desktopModules.darwin;

    moduleNames = lib.attrNames availableModules;
in
{
    options.modules.desktop = {
        enable = mkEnableOption "Enable desktop environment";
        environment = mkOption {
            type = lib.types.enum moduleNames;
            default = lib.head moduleNames;
            description = "Desktop environment to enable.";
        };
    };
    config = lib.mkIf cfg.enable {
        imports = [ availableModules.${config.modules.desktop.environment} ]
    };
}
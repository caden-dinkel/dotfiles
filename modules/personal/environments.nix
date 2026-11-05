{ config, lib, pkgs, name, ... }:
let
  cfg = config.roles.personal.user.environment;
in
{
  config = lib.mkMerge [
    (lib.mkIf (cfg.gnome.enable && pkgs.stdenv.hostPlatform.isLinux) {
      services.desktopManager.gnome.enable = true;
      services.displayManager.gdm.enable = true;
    })
    (lib.mkIf (cfg.yabai.enable && pkgs.stdenv.hostPlatform.isDarwin) {
      system.primaryUser = name;
    services.yabai = {
      enable = true;
      enableScriptingAddition = false;
      config = {
        layout = "bsp";
        focus_follows_mouse = "autoraise";
        window_placement = "second_child";
        window_opacity = "off";
        top_padding = 10;
        bottom_padding = 10;
        left_padding = 10;
        right_padding = 10;
        window_gap = 10;
      };
    };
    })
  ];
}
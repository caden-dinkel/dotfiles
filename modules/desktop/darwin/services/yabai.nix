{ lib, pkgs, ... }:
{
    config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        services.yabai = {
            enable = true;
            package = pkgs.yabai;
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
            # Going to try this out for a while.
            /*
            extraConfig = ''
              yabai -m rule --add app="^System Settings$" manage=off
            '';
            */
        };
    };
}

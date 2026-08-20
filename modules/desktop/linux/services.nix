{ pkgs, ... }:
{
    services.greetd = {
        enable = true;
        settings = {
            default_session = {
                command = "${pkgs.tuigreet}/bin/tuigreet --cmd Hyprland";
            };
        };
    };

    services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
    };
}
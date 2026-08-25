{ inputs, config, self, pkgs, lib, moduleType, ... }:
let
    username = "cdink";
    userDescription = "Caden Dinkel";
    git = {
        name = "Caden Dinkel";
        email = "git@cdink.dev";
        username = "caden-dinkel";
    };
in
{
    imports = [
        ../modules
        ../users/personal-user.nix
        inputs.home-manager.${moduleType}.home-manager
        ../modules/home
    ];

    config = lib.mkMerge [
    {
        _module.args = { inherit username userDescription git; };

        fonts.packages = [
            pkgs.nerd-fonts.hack
            pkgs.nerd-fonts.jetbrains-mono
            pkgs.noto-fonts
            pkgs.noto-fonts-emoji
        ];
    }
    ( lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        xdg.portal.extraPortals = [
            pkgs.xdg-desktop-portal-hyprland
            pkgs.xdg-desktop-portal-gtk
        ];

        networking.networkmanager.enable = true;
        hardware.bluetooth.enable = true;

        # Will want this more permissive for a personal machine probably.
        networking.firewall = {
            enable = true;
            trustedInterfaces = [ "tailscale0" ];
            allowedUDPPorts = [ config.services.tailscale.port ];
        };

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
    })
    ( lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        nix.linux-builder = {
            enable = true;
            package = pkgs.darwin.linux-builder-vz;
            systems = [
                "aarch64-linux"
                "x86_64-linux"
            ];

            ephemeral = true;
            maxJobs = 4;
            config = {
                virtualisation = {
                    darwin-builder = {
                        diskSize = 40 * 1024;
                        memorySize = 8 * 1024;
                    };
                    cores = 6;
                };
            };
        };
        security.pam.services.sudo_local = {
            enable = true;
            touchIdAuth = true;
            reattach = true;
        };
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
        };
    })
    ];
} 
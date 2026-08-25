{ lib, pkgs, ... }:
{
    config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        home.packages = [
            pkgs.maccy
            pkgs.tailscale-gui
        ];
    };
}

{ lib, pkgs, ... }:
{
    config = lib.mkIf pkgs.stdenv.isDarwin {
        home.packages = [
            pkgs.maccy
            pkgs.tailscale-gui
        ];
    };
}

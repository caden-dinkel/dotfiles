{ lib, pkgs, ... }:
{
    config = lib.mkIf pkgs.stdenv.isLinux {
        home.packages = [
            pkgs.xdg-utils
        ];
    };
}

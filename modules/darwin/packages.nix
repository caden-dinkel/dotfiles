{ lib, pkgs, ... }:
{
    config = lib.mkIf pkgs.stdenv.isDarwin {
        environment.systemPackages = [
            pkgs.vfkit
        ];
    };
}

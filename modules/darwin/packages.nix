{ lib, pkgs, ... }:
{
    config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        environment.systemPackages = [
            pkgs.vfkit
        ];
    };
}

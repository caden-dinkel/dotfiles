{ lib, pkgs, ... }:
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    services.skhd = {
        enable = true;
    };
}
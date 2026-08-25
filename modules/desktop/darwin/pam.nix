{ lib, pkgs, ... }:
{
    config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        security.pam.services.sudo_local = {
            enable = true;
            touchIdAuth = true;
            # Don't have my watch setup yet. Don't want to look up key again.
            # watchIdAuth = true;
            reattach = true;
        };
    };
}

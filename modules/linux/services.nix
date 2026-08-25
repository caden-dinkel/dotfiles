{ lib, pkgs, ... }:
{
    config = lib.mkIf pkgs.stdenv.isLinux {
        services.openssh = {
            enable = true;
            ports = [ 2222 ];
            settings = {
                PasswordAuthentication = false;
                PermitRootLogin = "no";
            };
        };
    };
}

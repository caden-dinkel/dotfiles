# This is a default role that everything should import (nixos or nix-darwin).
{ pkgs, ... }:
{
    system.stateVersion = if pkgs.stdenv.hostPlatform.isLinux
    then "26.05"
    else 6;

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
}
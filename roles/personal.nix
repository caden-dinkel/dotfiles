# This is a dev role that dev machiens should import (nixos or nix-darwin).
{ config, ... }:
{
    imports = [
        ../modules/terminal-emulator
    ];
}
# This is a dev role that dev machiens should import (nixos or nix-darwin).
{
    imports = [
        ../modules/terminal-emulator
    ];
}
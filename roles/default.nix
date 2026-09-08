# This is a default role that everything should import (nixos or nix-darwin).
{
    imports = [
        ../modules/state-version
    ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
}
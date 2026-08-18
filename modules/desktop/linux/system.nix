{
    xdg.portal.extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
    ];

    networking.networkmanager.enable = true;
    hardware.bluetooth.enable = true;
};
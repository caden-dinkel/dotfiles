{
    services.desktopManager.gnome.enable = true;
    services.displayManager.gdm.enable = true;

    environment.systemPackages = [
        pkgs.gnome-tweaks
    ];

    environment.gnome.excludePackages = (with pkgs; [
        gnome-tour
        epiphany
        geary
    ]);
}
{ userName, ... }:
{
    home-manager.users."${userName}" = {
        home.packages = [
            pkgs.bitwarden-desktop
        ];
    };
}
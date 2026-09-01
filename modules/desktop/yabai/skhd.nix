{ userName, ... }:
{
    home-manager.users."${userName}" = {
        services.skhd = {
            enable = true;
        };
    };
}
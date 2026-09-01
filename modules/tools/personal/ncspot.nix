{ userName, ... }:
{
    home-manager.users."${userName}" = {
        programs.ncspot = {
            enable = true;
        };
    };
}
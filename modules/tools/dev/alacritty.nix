{ userName, ... }:
{
    home-manager.users."${userName}" = {
        programs.alacritty = {
            enable = true;
        };
    };
}
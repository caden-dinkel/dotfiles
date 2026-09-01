{ userName, ... }:
{
    home-manager.users."${userName}" = {
        programs.claude-code = {
            enable = true;
        };
    };
}
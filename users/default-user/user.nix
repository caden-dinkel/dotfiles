{ userName, userDescription, ... }:
{
    users.users."${userName}" = {
        description = userDescription;
        home = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${userName}" else "/home/${userName}";
    };
}
{ userName, userDescription, ... }:
{
    users.users."${userName}" = {
        description = userDescription;
    };
}
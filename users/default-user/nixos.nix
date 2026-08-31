{ userName, ... }:
{
    users.users."${userName}" = {
        createHome = true;

        isNormalUser = true;

        extraGroups = [
            "wheel"
            "networkmanager" 
            "bluetooth" 
        ];

        shell = pkgs.zsh;
    };
}
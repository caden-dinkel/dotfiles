{ pkgs, ... }:
{
    system = "aarch64-linux";
    users.users.builder = {
        isNormalUser = true;
        openssh.authorizedKeys.keys = [
            "<your ssh key>"
        ];
    };

    networking.firewall.allowedTCPPorts = [ 22 ];


    services.openssh.enable = true;


    nix.settings.trusted-users = [ "builder" ];
    nix.settings.experimental-features = [
        "nix-command"
        "flakes"
    ];

    system.stateVersion = "26.05";
}
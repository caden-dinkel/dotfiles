{ pkgs }:
{
    networking.hostName = "test-node";
    
    services.openssh.enable = true;
    services.openssh.settings.PermitRootLogin = "no";

    users.users.caden = {
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPQSQpXpm7lmsfqUnyUzRD+h3CkXVlxPKyhMOSxAa7ml mac@cdink.dev"
        ];
        packages = with pkgs; [
            vim
        ];
    };

    microvm = {
        shares = [ {
            tag = "ro-store";
            proto = "virtiofs";
            source = "/nix/store";
        } ];
        interfaces = [ {
            type = "user"; # Simple user-networking (NAT)
            id = "vm-nic";
        } ];
    };
}
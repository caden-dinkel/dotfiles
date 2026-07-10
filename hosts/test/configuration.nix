{ pkgs }:
{
    networking.hostName = "test-node";
    
    # Enable SSH so you can test deploy-rs
    services.openssh.enable = true;
    services.openssh.settings.PermitRootLogin = "yes";

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
{
    environment.persistence."/persist" = {
        enable = true;
        hideMounts = true;
        directories = [
            "/var/lib/tailscale"
            "/var/lib/nixos"
            "/etc/ssh"
            "/etc/NetworkManager/system-connections"
            "/var/log"
        ];
        files = [
            "/etc/machine-id"
        ];
    };
}
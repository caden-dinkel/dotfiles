{
    programs.ssh = {
        enable = true;
        settings = {
            "github.com" = {
                HostName = "github.com";
                User = "git";
            };
        };
    };
}
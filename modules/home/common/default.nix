{
    # Pull in/configure common defaults, pulled into every system with home-manager.
    # Allow systems to pull darwin/linux explicitly.
    imports = [
        ./git.nix
        ./programs.nix
        ./home.nix
        ./ssh.nix
    ];
}
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.cdink = {
      imports = [
        ./programs.nix
        ./git.nix
        ./ssh.nix
      ];
    };
  };
}

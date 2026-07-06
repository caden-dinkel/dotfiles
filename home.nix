{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.cdink = {
      imports = [
        ./programs.nix
      ];
    };
  };
}

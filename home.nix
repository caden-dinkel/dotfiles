{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.cdink = {
      imports = [
        ./cdink.nix
      ];
    };
  };
}

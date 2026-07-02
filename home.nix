{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.cdink = {
      imports = [
        ./home/cdink.nix;
      ];
    };
  };
}

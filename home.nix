{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.cdink = import ./home/cdink.nix;
  };
}

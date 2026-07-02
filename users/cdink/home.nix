{ home-manager, ... }:

{
  home-manager.darwinModules.home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.cdink = { pkgs, ... }:
    {
      home.pkgs = [
        pkgs.bitwarden-desktop
      ];
    };
  };
}

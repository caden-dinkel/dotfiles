{ userName, pkgs, lib, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users."${userName}" = {
      imports = [
        ./common
      ] ++ lib.optionals pkgs.stdenv.isDarwin [
        ./darwin
      ] ++ lib.optionals pkgs.stdenv.isLinux [
        ./linux
      ];
    };
  };
}

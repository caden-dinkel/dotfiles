{ homeUser, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users."${homeUser}" = {
      # This tree handles home-manager
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

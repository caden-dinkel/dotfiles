{ userName, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users."${userName}" = {
      imports = [
        ./common
        ./darwin
        ./linux
      ];
    };
  };
}

{ pkgs, ... }:
{
  home = {
    stateVersion = "26.05";
    # May consider moving this to a packages.nix file and importing
    packages = [
      pkgs.bitwarden-cli
      pkgs.tree
    ];
  };
}
{ inputs, moduleType, ... }:
{
  imports = [
    inputs.home-manager.${moduleType}.home-manager
    ./home.nix
  ];
}
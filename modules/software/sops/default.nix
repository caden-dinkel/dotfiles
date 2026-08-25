{ inputs, pkgs, moduleType, ... }:
{
  imports = [
    inputs.sops-nix.${moduleType}.sops
    ./sops.nix
  ];
}
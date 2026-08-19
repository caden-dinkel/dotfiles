{ inputs, pkgs, ... }:
let
  systemModules = if pkgs.stdenv.isLinux then "nixosModules" else "darwinModules";
in
{
  imports = [
    inputs.sops-nix.${systemModules}.sops
    ./sops.nix
  ];
}
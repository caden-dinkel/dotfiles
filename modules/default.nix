{ lib, pkgs, ... }:
{
    imports = [
        ./common.nix
        ./nixos.nix
        ./darwin.nix
    ];
}
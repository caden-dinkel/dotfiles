{ lib, pkgs, ... }:
{
    imports = [
        ./common.nix
    ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        ./nixos.nix
    ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        ./darwin.nix
    ];
}
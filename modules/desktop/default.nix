{ pkgs, ... }:
{
    imports = [
        ./common
    ] ++ lib.optionals pkgs.stdenv.isDarwin [
        ./darwin
    ] ++ lib.optionals pkgs.stdenv.isLinux [
        ./linux
    ];
}
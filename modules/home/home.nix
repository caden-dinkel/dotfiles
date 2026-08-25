{ username, lib, pkgs, ... }:
{
    home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
    };

    users."${username}" = {
        home = {
            stateVersion = "26.05";
            packages = [
                pkgs.bitwarden-cli
                pkgs.tree
                pkgs.tmux
            ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                pkgs.xdg-utils
            ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
                pkgs.maccy
                pkgs.tailscale-gui
            ];
        };
        imports = [
            ./common.nix
            ./darwin.nix
            ./nixos.nix
        ];
    };
}
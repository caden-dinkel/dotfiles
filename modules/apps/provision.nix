{ pkgs, lib, ... }:
let
    supportedSystems = [ 
        "x86_64-linux" 
        "aarch64-linux" 
        "aarch64-darwin" 
        "x86_64-darwin" 
    ];
    forAllSystems = lib.genAttrs supportedSystems;
in
{
    forAllSystems (system:
        let
            pkgs = nixpkgs.legacyPackages.${system};
            provisionScript = pkgs.writeShellApplication {
                name = "provision-host";
                runtimeInputs = [
                    pkgs.coreutils
                    pkgs.age
                    pkgs.openssh
                    nixos-anywhere.packages.${system}.nixos-anywhere
                ];
                # Three phases. 
                # 1. Get one time use auth key (tailscale API).
                # 2. Generate age key.
                # 3. Place in files based on the flake's designation. (Not sure here.)
                text = ''
                
                '';
            };
        in
        {
            provision = {
                type = "app";
                program = "${provisionScript}/bin/provision-host";
            };
        }
    );
}
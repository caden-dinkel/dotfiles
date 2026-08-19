{ ... }:
let
    supportedSystems = [ 
        "x86_64-linux" 
        "aarch64-linux" 
        "aarch64-darwin" 
        "x86_64-darwin" 
    ];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
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
                text = ''
                    # Script goes here.
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
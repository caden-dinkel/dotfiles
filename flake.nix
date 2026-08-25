{
    description = "Refactor of multi-system, multi-function flake.";
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    
        nix-darwin = {
            url = "github:nix-darwin/nix-darwin/master";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        sops-nix = {
            url = "github:Mic92/sops-nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        disko = {
            url = "github:nix-community/disko";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        nixos-anywhere = {
            url = "github:nix-community/nixos-anywhere";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        impermanence.url = "github:nix-community/impermanence";

        deploy-rs.url = "github:serokell/deploy-rs";
    };
    outputs = {
        self, 
        nix-darwin, 
        nixpkgs, 
        home-manager, 
        sops-nix, 
        disko, 
        nixos-anywhere,
        impermanence, 
        deploy-rs,
        ... 
    }:
    {
        nixosConfigurations = {
            bravo = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                specialArgs = { 
                    inherit self; 
                    inputs = self.inputs; 
                    moduleType = "nixosModules";
                };
                modules = [
                    ./hosts/bravo
                ];
            };
            charlie = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                specialArgs = { 
                    inherit self; 
                    inputs = self.inputs; 
                    moduleType = "nixosModules";
                };
                modules = [
                    ./hosts/charlie
                ];
            };
        };
        darwinConfiguration = {
            alpha = nix-darwin.lib.darwinSystem {
                system = "aarch64-darwin";
                specialArgs = { 
                    inherit self; 
                    inputs = self.inputs; 
                    moduleType = "darwinModules";
                };
                modules = [
                    ./hosts/alpha
                ];
            };
        };
        deploy.nodes = {
            charlie = {
                hostname = "charlie.rainbow-dorian.ts.net";
                profiles.system = {
                    user = "root";
                    sshUser = "deploy";
                    sshOpts = [ "-p" "2222" ];
                    path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.charlie;
                };
            };
        };
    };
}
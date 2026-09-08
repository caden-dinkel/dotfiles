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
                specialArgs = { 
                    inherit self; 
                    inputs = self.inputs; 
                };
                modules = [
                  disko.nixosModules.disko
                  ./hosts/bravo
                ];
            };
        };
        darwinConfiguration = {
            alpha = nix-darwin.lib.darwinSystem {
                specialArgs = { 
                    inherit self; 
                    inputs = self.inputs; 
                };
                modules = [
                  ./hosts/alpha
                ];
            };
        };
    };
}
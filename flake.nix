{
  description = "Example nix-darwin system flake";


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

    microvm = {
      url = "github:microvm-nix/microvm.nix";
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

    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs = { self, nix-darwin, nixpkgs, ... }@inputs:
  {
    darwinConfigurations."mac-m3" = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit self home-manager sops-nix inputs; };
      modules = [
        home-manager.darwinModules.home-manager
        sops-nix.darwinModules.sops
        ./hosts/darwin/configuration.nix
      ];
    };

    nixosConfigurations."omen" = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit self disko inputs; };
      modules = [
        inputs.disko.nixosModules.disko
        ./hosts/omen/configuration.nix
      ];
    };
  };
}

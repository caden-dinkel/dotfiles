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
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, microvm }:
  {
    darwinConfigurations."mac-m3" = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit self inputs; };
      modules = [
        ./hosts/darwin/configuration.nix
      ];
    };

    nixosConfigurations."test-microvm" = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit self inputs; };
      modules = [
        ./hosts/test/configuration.nix
      ];
    };
  };
}

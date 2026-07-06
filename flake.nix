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
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Cadens-MacBook-Pro
    darwinConfigurations."mac-m3" = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit self inputs; };
      modules = [
        ./hosts/darwin/configuration.nix
      ];
    };
    nixosConfigurations.builder = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit self inputs; };
      modules = [
        ./hosts/builder/configuration.nix
      ];
    };
  };
}

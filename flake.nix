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
  outputs = inputs@{
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
  let
    name = "cdink";
    git = {
      name = "Caden Dinkel";
      email = "git@cdink.dev";
    };
  in
  {
    darwinConfigurations.alpha = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit self inputs git name home-manager; };
      system = "aarch64-darwin";
      modules = [
        ./hosts/alpha
      ];
    };

    nixosConfigurations.beta = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit self inputs git name home-manager; };
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./hosts/bravo
      ];
    };

    nixosConfigurations.charlie = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit self inputs; };
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./hosts/charlie
      ];
    };
  };
}
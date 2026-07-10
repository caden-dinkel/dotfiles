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
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    }; 
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
  {
    darwinConfigurations."mac-m3" = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit self inputs; };
      modules = [
        ./hosts/darwin/configuration.nix
      ];
    };

    apps."aarch64-darwin".run-test-vm = {
      type = "app";
      program = let
        microvmSystem = microvm.lib.nixosAsVm {
          system = "aarch64-linux";
          modules = [
            ({ pkgs, ... }: {
              networking.hostName = "test-node";

              services.openssh.enable = true;
            })
          ];
        };
    };
  };
}

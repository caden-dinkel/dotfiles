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

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    deploy-rs.url = "github:serokell/deploy-rs";
  };
  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      sops-nix,
      disko,
      nixos-anywhere,
      impermanence,
      deploy-rs,
      treefmt-nix,
      ...
    }:
    let
      name = "cdink";
      git = {
        name = "Caden Dinkel";
        email = "git@cdink.dev";
      };

      # treefmt - Directly from docs-ish.
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      eachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./modules/treefmt.nix);
    in
    {
      formatter = eachSystem (pkgs: treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper);

      checks = eachSystem (pkgs: {
        formatting = treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.check self;
      });

      darwinConfigurations.alpha = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit
            self
            inputs
            git
            name
            home-manager
            ;
        };
        system = "aarch64-darwin";
        modules = [
          ./hosts/alpha
        ];
      };

      nixosConfigurations.bravo = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit
            self
            inputs
            git
            name
            home-manager
            ;
        };
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

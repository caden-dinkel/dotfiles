{
  description = "Refactor of multi-system, multi-function flake.";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
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

    microvm = {
      url = "github:microvm-nix/microvm.nix";
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
      microvm,
      ...
    }:
    let
      name = "cdink";
      git = {
        name = "Caden Dinkel";
        email = "git@cdink.dev";
      };

      tailscaleDomain = "";

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      eachSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
      treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./modules/treefmt.nix);
    in
    {

      formatter = eachSystem (pkgs: treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper);

      checks = eachSystem (pkgs: {
        formatting = treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.check self;
      });

      nixosConfigurations.my-microvm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          microvm.nixosModules.microvm
          {
            networking.hostName = "my-microvm";
            system.stateVersion = "26.05";
            microvm.hypervisor = "qemu";
            microvm.interfaces = [
              {
                type = "tap";
                id = "enp5s0";
                mac = "46:9e:18:1a:74:b5";
              }
            ];
          }
        ];
      };

      darwinConfigurations.alpha = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit
            self
            inputs
            git
            name
            home-manager
            sops-nix
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
            sops-nix
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

      deploy.nodes.charlie = {
        hostname = "charlie.${tailscaleDomain}";
        # This private ssh key (above) is decrypted at runtime by sops-nix
        # I can assume that this is the case, and try to reference /run/secrets/deploy-rs-key
        profiles.system = {
          sshUser = "deploy";
          sshOpts = [
            "-i"
            "/run/secrets/deploy-rs-key"
          ];
          user = "root";
          path = deploy-rs.lib.x86_linux.activate.nixos self.nixosConfigurations.charlie;
        };
      };

      packages =
        builtins.mapAttrs (system: pkgs: {
          "create-deploy-key" = import ./scripts/create-deploy-key.nix { inherit pkgs; };

          "get-tailscale-authkey" = import ./scripts/get-tailscale-authkey.nix { inherit pkgs; };

          "create-nix-cache-key" = import ./scripts/create-nix-cache-key.nix { inherit pkgs; };

          "provision-new-machine" = import ./scripts/provision-new-machine.nix {
            inherit
              pkgs
              system
              self
              ;
            nixos-anywhere = inputs.nixos-anywhere.packages.${system}.default;
          };
        }) inputs.nixpkgs.legacyPackages
        // {
          x86_64-linux.my-microvm = self.nixosConfigurations.my-microvm.config.microvm.declaredRunner;
        };
    };
}

{
  description = "Nix-darwin user system flake and impermanent nixos headless system flake";


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

    impermanence.url = "github:nix-community/impermanence";

    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs = { 
    self, 
    nix-darwin, 
    nixpkgs, 
    home-manager, 
    microvm, 
    sops-nix, 
    disko, 
    impermanence, 
    deploy-rs, 
    ... }:
      let
        hostsByArch = {
          x86_64-linux = [ "omen" ];
          aarch64-linux = [];
        };

        mkSystem = system: hostname: nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit self; };
          modules = [
            impermanence.nixosModules.impermanence
            disko.nixosModules.disko
            ./hosts/${hostname}/configuration.nix
          ];
        };


        mkNode = system: hostname: {
          hostname = "${hostname}.rainbow-dorian.ts.net";
          profiles.system = {
            user = "root";
            sshUser = "deploy";
            path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.${hostname};
          };
        };

        forEachHost = f:
          nixpkgs.lib.concatMapAttrs (system: hosts:
            builtins.listToAttrs (map (hostname: {
              name = hostname;
              value = f system hostname;
            }) hosts)
          ) hostsByArch;
      in
    {
      darwinConfigurations."mac-m3" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit self; };
        modules = [
          home-manager.darwinModules.home-manager
          sops-nix.darwinModules.sops
          ./hosts/darwin/configuration.nix
        ];
      };

      nixosConfigurations = forEachHost mkSystem;

      deploy.nodes = forEachHost mkNode;

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}

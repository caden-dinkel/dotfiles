{
  description = "I'll Write this later.";


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
        hostNames = builtins.attrNames (
          nixpkgs.lib.filterAttrs (n: t: t == "directory") (builtins.readDir ./hosts)
        );

        getMeta = name: import ./hosts/${name}/metadata.nix;

        deployableHosts = nixpkgs.lib.filter (name: 
          (getMeta name).deployable or false)
          hostNames;
      in
      {
        nixosConfigurations = nixpkgs.lib.genAttrs 
          (nixpkgs.lib.filter (n: (getMeta n).type == "nixos") hostNames) 
          (name: nixpkgs.lib.nixosSystem {
            system = (getMeta name).system;
            specialArgs = { inherit self; };
            modules = [ ./hosts/${name} ];
          });

        darwinConfigurations = nixpkgs.lib.genAttrs 
          (nixpkgs.lib.filter (n: (getMeta n).type == "darwin") hostNames) 
          (name: nix-darwin.lib.darwinSystem {
            system = (getMeta name).system;
            specialArgs = { inherit self; };
            modules = [ ./hosts/${name} ];
          });
          deploy.nodes = nixpkgs.lib.genAttrs deployableHosts (name: {
            hostname = "${name}.rainbow-dorian.ts.net";
            profiles.system = {
              user = "root";
              sshUser = "deploy";
              path = deploy-rs.lib.${(getMeta name).system}.activate.nixos self.nixosConfigurations.${name};
            };
          });
      };
}

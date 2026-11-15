{
  lib,
  host,
  isVm,
  ...
}:
let
  hosts = {
    alpha = {
      platform = "aarch64-darwin";
      hardware = ../profiles/macbook.nix;
      software = ./alpha;
    };
    bravo = {
      platform = "x86_64-linux";
      hardware = ../profiles/desktop.nix;
      software = ./bravo;
    };
    charlie = {
      platform = "x86_64-linux";
      hardware = ../profiles/omen.nix;
      software = ./charlie;
    };
  };
  vmHardware = ../../profiles/vm.nix;
  selectedHost = hosts.${host} or (throw "Unknown host: ${host}");
in
  {
    imports = [
      selectedHost.software
    ]
    ++ lib.optionals (!isVm) [
      selectedHost.hardware
    ]
    ++ lib.optionals isVm [
      vmHardware
    ];
  }

/*
  systemModules =
    if selectedHost.platform == "aarch64-darwin" then "darwinModules" else "nixosModules";
  createSystem =
    if selectedHost.platform == "aarch64-darwin" then
      nix-darwin.lib.darwinSystem
    else
      nixpkgs.lib.nixosSystem;
  inputModules = {
    home-manager = "home-manager";
    sops-nix = "sops";
    disko = "disko";
    impermanence = "impermanence";
    microvm = "microvm";
  };

  
in
createSystem {
  system = selectedHost.platform;
  modules = [
    
  ];
}
 */
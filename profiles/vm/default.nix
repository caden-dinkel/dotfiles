{ microvm, ... }:{
  imports = [
    microvm.nixosModules.microvm
    ./vm.nix
  ];
}
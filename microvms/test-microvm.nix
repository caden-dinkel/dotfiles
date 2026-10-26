{ nixpkgs, microvm }:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    microvm.nixosModules.microvm
    {
      networking.hostName = "test-microvm";
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
}

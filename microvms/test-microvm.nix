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
          type = "user";
        }
      ];
    }
  ];
}

{ nixpkgs, microvm }:
{
  nixosConfigurations.test-microvm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          microvm.nixosModules.microvm
          {
            networking.hostName = "test-microvm";
            system.stateVersion = "26.05";
            microvm.hypervisor = "qemu";
            microvm.interfaces = [

            ];
            microvm.volumes = [
              {
                image = "../images/main.raw";
              }
              {

              }
            ];
          }
        ];
      };
}
{ nixpkgs, microvm }:
{
  nixosConfigurations.ssh-blank = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          microvm.nixosModules.microvm
          {
            networking.hostName = "ssh-blank";
            system.stateVersion = "26.05";
            services.openssh = {
              enable = true;
            };
            # Need to add generation of these keys to test script.
            users.users.root.openssh.authorizedKeys.keyFiles = [
              ../secrets/test-key.pub
            ];
            microvm.hypervisor = "qemu";
            microvm.interfaces = [

            ];
            microvm.volumes = [
              {
                image = "../images/main.raw";
              }
              {
                image = "../images/secondary.raw";
              }
            ];
          }
        ];
      };
}
{ nixpkgs, microvm }:
nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    microvm.nixosModules.microvm
    {
      networking.hostName = "ssh-blank";
      system.stateVersion = "26.05";
      services.openssh = {
        enable = true;
      };
      /*
        services.headscale = {
          enable = true;
          address = "0.0.0.0";
          port = 8080;
          settings = {

          };
        };
      */
      networking.firewall.allowedTCPPorts = [ 8080 ];

      microvm.hypervisor = "qemu";

    }
  ];
}

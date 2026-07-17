{ self, pkgs, config, lib, ... }:
{
  networking.hostName = "luck";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  imports = [
    "${self}/modules/base.nix"
    "${self}/modules/nvidia.nix"
    "${self}/modules/disko.nix"
    "${self}/modules/tailscale.nix"
    "${self}/modules/users/deploy.nix"
  ];

  myHardware = {
    nvidia = {
        enable = true;
        package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
        prime = {
            enable = true;
            intelBusId = "PCI:0:2:0";
            nvidiaBusId = "PCI:1:0:0";
        };
    };

    storage = {
        enable = true;
        main = {
            enable = true;
            device = "/dev/nvme0n1";
            ESP = {
                enable = true;
                size = "1G";
            };
            swap = {
                enable = true;
                size = "16G";
            };
        };

        persistent = {
            enable = true;
            device = "/dev/sda";
            format = "ext4";
        };

        ephemeral = {
            enable = true;
            tmpfsSize = "4G";
            persistentDirectories = [
                "/var/lib/tailscale"
                "/etc/machine-id"
                "/etc/ssh"
            ];
        };
    };
  };
}
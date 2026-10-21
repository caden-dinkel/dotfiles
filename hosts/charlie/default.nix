# This device will be the binary cache.
{ config, ... }: {
  time.timeZone = "America/Chicago";

  imports = [
    ../../modules/common.nix
    ../../modules/state-version.nix
    ../../modules/tailscale.nix
    ../../modules/deploy-user.nix
    ../../modules/server.nix
  ]
  ++ (
    let
      hardwareConfig = ./hardware-configuration.nix;
    in
    if builtins.pathExists hardwareConfig then [ hardwareConfig ] else [ ]
  );

  myNetworking.tailscale = {
    enable = true;
    profile = "server";
    authKeyFile = /etc/tailscale/authkey;
  };

  myUsers.deploy = {
    enable = true;
    # Uses default ssh key.
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "charlie";

  nixpkgs.hostPlatform = "x86_64-linux";

  hardware = {
    graphics.enable = true;
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
      modesetting.enable = true;
      open = true;
      powerManagement = {
        enable = true;
        finegrained = true;
      };
    };
  };

  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.kernelParams = [
    "nvidia.NVreg_PreserveVideoMemoryAllocation=1"
  ];

  disko.devices.disk.primary.device = "/dev/disk/by-id/nvme-eui.002538b971031fda";
  disko.devices.disk.secondary.device = "/dev/disk/by-id/wwn-0x5000cca8d8ec939a";

  disko.devices.disk.secondary = {
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        backups = {
          size = "100%";
          content = {
            type = "btrfs";
            subvolumes = {
              "/backups" = {
                mountpoint = "/backups";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/backups/root" = {

              };
              "/backups/server_data" = {

              };
            };
          };
        };
      };
    };
  };
  disko.devices.disk.primary = {
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          name = "ESP";
          start = "1M";
          end = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        swap = {
          priority = 2;
          size = "32G";
          content = {
            type = "swap";
            discardPolicy = "both";
            resumeDevice = true;
          };
        };
        root = {
          priority = 3;
          size = "100%";
          content = {
            type = "btrfs";
            subvolumes = {
              "/rootfs" = {
                mountpoint = "/";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
              "/nix" = {
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
                mountpoint = "/nix";
              };
              "/root_blank" = { };
              "/persist" = {
                mountpoint = "/persist";
                mountOptions = [
                  "compress=zstd"
                  "noatime"
                ];
              };
            };
          };
        };
      };
    };
  };
}

{
  config,
  name,
  pkgs,
  home-manager,
  sops-nix,
  ...
}:
{
  time.timeZone = "America/Chicago";

  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    home-manager.nixosModules.home-manager
    sops-nix.nixosModules.sops
    ../../modules/sops.nix
    ../../modules/home.nix
    ../../modules/tailscale.nix
    ../../modules/minecraft.nix
  ];

  myNetworking.tailscale = {
    enable = true;
    profile = "personal";
  };

  # Allows non-root to execute root commands using sudo
  security.sudo.enable = true;
  system.stateVersion = "26.05";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "bravo";
  nixpkgs.hostPlatform = "x86_64-linux";
  hardware = {
    graphics.enable = true;
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      open = true;
      powerManagement.enable = true;
      powerManagement.finegrained = false;
      nvidiaSettings = true;
    };
  };

  boot.initrd.availableKernelModules = [
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia"
    "nvidia_uvm"
  ];

  boot.blacklistedKernelModules = [ "nouveau" ];

  boot.kernelParams = [
    "nvidia.NVreg_PreserveVideoMemoryAllocation=1"
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  programs.obs-studio = {
    enable = true;
    package = (
      pkgs.obs-studio.override {
        cudaSupport = true;
      }
    );
  };

  # Primary, secondary, ternary, ... naming scheme.
  disko.devices.disk.primary.device = "/dev/disk/by-label/nvme-eui.e8238fa6bf530001001b448b4c504ccd";
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
              "/home" = {
                mountOptions = [ "compress=zstd" ];
                mountpoint = "/home";
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
  

  users.users.${name} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
}

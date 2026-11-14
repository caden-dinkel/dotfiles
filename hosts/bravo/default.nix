{
  config,
  name,
  pkgs,
  home-manager,
  sops-nix,
  ...
}:
{
  nixpkgs.hostPlatform = "x86_64-linux";

  time.timeZone = "America/Chicago";

  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    home-manager.nixosModules.home-manager
    sops-nix.nixosModules.sops
    ../../modules/sops.nix
    ../../modules/home/home.nix
    ../../modules/tailscale.nix
    ../../modules/minecraft-client.nix
  ];

  myNetworking.tailscale = {
    enable = true;
    profile = "personal";
  };

  # Allows non-root to execute root commands using sudo
  security.sudo.enable = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "bravo";
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
    plugins = [
      pkgs.obs-studio-plugins.obs-pipewire-audio-capture
    ];
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

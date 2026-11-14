{
  config,
  name,
  pkgs,
  home-manager,
  sops-nix,
  disko,
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
    disko.nixosModules.disko
    ./disko.nix
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

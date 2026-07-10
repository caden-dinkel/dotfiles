{ self, pkgs, inputs, ... }:
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget

  imports = [
    ./user.nix
    ./pam.nix
    inputs.home-manager.darwinModules.home-manager
    ../../home/home.nix
  ];
  
  environment.systemPackages = [
    pkgs.vim
    pkgs.helix
    pkgs.vfkit
  ];

  nix.settings.experimental-features = "nix-command flakes";

  nix.distributedBuilds = true;

  nix.linux-builder = {
    enable = true;
    ephemeral = true; # Wipes the VM state on reboot (keeps things clean)
    maxJobs = 4;      # Adjust based on your M3 core count
    systems = [ "aarch64-linux" ];
    config = {
      virtualisation = {
        darwin-builder = {
          diskSize = 40 * 1024; # 40 GB disk size
          memorySize = 8192;    # 8 GB RAM
        };
      };
    };
  };

  nix.settings.trusted-users = [ "@admin" ];

  nixpkgs.config.allowUnfree = true;

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.primaryUser = "cdink";
  
  system.defaults = {
    finder = {
      AppleShowAllFiles = true;
      AppleShowAllExtensions = true;
    };
    NSGlobalDomain = {
      AppleShowAllFiles = true;
      _HIHideMenuBar = true;
    };
    dock.autohide = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.hack
  ];
  
  system.stateVersion = 6;

  nixpkgs.hostPlatform = "aarch64-darwin";

  services.yabai = {
    enable = true;
    package = pkgs.yabai;
    enableScriptingAddition = false;
    config = {
      layout = "bsp";
      focus_follows_mouse = "autoraise";
      window_placement = "second_child";
      window_opacity = "off";
      top_padding = 10;
      bottom_padding = 10;
      left_padding = 10;
      right_padding = 10;
      window_gap = 10;
    };
    extraConfig = ''
      yabai -m rule --add app="^System Settings$" manage=off
    '';
  };

  services.skhd = {
    enable = true;
    package = pkgs.skhd;

    skhdConfig = ''
      cmd - return : open -na "/Users/cdink/Applications/Home Manager Apps/WezTerm.app"
    '';
  };
}

{
  name,
  pkgs,
  home-manager,
  ...
}:
{

  time.timeZone = "America/Chicago";
  imports = [
    ../../modules/common.nix
    home-manager.darwinModules.home-manager
    ../../modules/home.nix
    ../../modules/tailscale.nix
  ];

  users.users.${name} = {
    home = "/Users/${name}";
  };

  system.stateVersion = 6;
  networking.hostName = "alpha";
  nixpkgs.hostPlatform = "aarch64-darwin";
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    # Don't have my watch setup yet. Don't want to look up key again.
    # watchIdAuth = true;
    reattach = true;
  };

  nix.linux-builder = {
    enable = true;
    package = pkgs.darwin.linux-builder; # -vz; # Add vz back when package set is updated/build machine is up.
    systems = [
      "aarch64-linux"
      "x86_64-linux"
    ];

    ephemeral = true;
    maxJobs = 4;
    config = {
      virtualisation = {
        darwin-builder = {
          diskSize = 40 * 1024;
          memorySize = 8 * 1024;
        };
        cores = 6;
      };
    };
  };

  nix.settings.trusted-users = [ "@admin" ];

  # Primary User is required for yabai.
  system.primaryUser = name;
  services.yabai = {
    enable = true;
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
  };
}

{
  name,
  pkgs,
  config,
  lib,
  ...
}:
let
  myHomeDir = if pkgs.stdenv.hostPlatform.isLinux then "/home/${name}" else "/Users/${name}";
  zshContent = ''
    alias ll="ls -alF"
  ''
  + (
    if pkgs.stdenv.hostPlatform.isLinux then
      ''
        alias rebuild="sudo nixos-rebuild switch --flake .#${config.networking.hostName}"
      ''
    else
      ''
        alias rebuild="sudo darwin-rebuild switch --flake .#${config.networking.hostName}"
      ''
  );
in
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.users.${name} = {
    home.packages = [
      pkgs.bitwarden-desktop
      pkgs.spotify
    ]
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      pkgs.freecad
    ];
    home.homeDirectory = myHomeDir;
    home.stateVersion = "26.05";
    
    
    
      programs.alacritty = {
        theme = "ashes_dark";
        enable = true;
        settings = {
          terminal.shell = {
            program = "${pkgs.zsh}/bin/zsh";
            args = [ "-l" ];
          };
        };
      };

      
      
      programs.obsidian = {
        enable = true;
      };

      programs.starship = {
        enable = true;
      };
      programs.zoxide = {
        enable = true;
        enableZshIntegration = true;
        options = [
          "--cmd cd" # This replaces the cd command with zoxide
        ];
      };
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        initContent = zshContent;
      };
      
    };
    # System Wide
    # from https://discourse.nixos.org/t/declare-firefox-extensions-and-settings/36265
    programs.firefox = {
      enable = true;
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
        DisablePocket = true;
        DisableFirefoxAccounts = true;
        DisableAccounts = true;
        DisableFirefoxScreenshots = true;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        DontCheckDefaultBrowser = true;
        ExtensionSettings = {
          "*".installation_mode = "blocked"; # blocks all addons except the ones specified below
          # uBlock Origin:
          "uBlock0@raymondhill.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
          };
          # Privacy Badger:
          "jid1-MnnxcxisBPnSXQ@jetpack" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
            installation_mode = "force_installed";
          };
        };
      };
    };
}

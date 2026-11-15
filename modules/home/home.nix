{
  config,
  lib,
  pkgs,
  ...
}:
let
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
  cfg = config.myUsers;
  userType = lib.types.submodule (
    { name, ... }: {
      options = {
        enable = lib.mkEnableOption "Enable home management for specified user.";
        user = lib.mkOption {
          type = lib.types.str;
          default = name;
          example = "alice";
          description = "Name of account to be managed by home-manager. Default is name of attribute set.";
        };
        dev = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            example = true;
            description = "Enable/Disable dev dependencies (ide, ssh, git, etc.)";
          };
          git = {
            name = lib.mkOption {
              type = lib.types.str;
              default = name;
              example = "alice smith";
              description = "Name for git commits.";
            };
            email = lib.mkOption {
              type = lib.types.str;
              default = name;
              example = "alice smith";
              description = "Email for git commits.";
            };
          };
        };
      };
    }
  );
in
{
  options.myUsers = {
    enable = lib.mkEnableOption "Enable home management for machine.";
    home = lib.mkOption {
      type = lib.types.attrsOf userType;
      default = { };
      example = {
        alice = {
          dev = true;
        };
      };
      description = "Attribute set of users to manage with home-manager.";
    };
  };
  config = lib.mkIf cfg.enable {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "backup";
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
    home-manager.users = lib.mapAttrs (
      name: userCfg:
      lib.mkMerge [
        {
          home.username = userCfg.user;
          home.homeDirectory =
            if pkgs.stdenv.hostPlatform.isLinux then "/home/${userCfg.user}" else "/Users/${userCfg.user}";
          home.packages = [
            pkgs.bitwarden-desktop
            pkgs.spotify
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            pkgs.freecad
          ];
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
        }
        (lib.mkIf userCfg.dev.enable {
          home.packages = [
            pkgs.helix
            pkgs.dust
            pkgs.pciutils
            pkgs.tree
            pkgs.ripgrep
            pkgs.nil
            pkgs.nixfmt
          ];
          programs.git = {
            enable = true;
            ignores = [ "**/.DS_Store" ];
            settings = {
              user = {
                name = userCfg.dev.git.name;
                email = userCfg.dev.git.email;
              };
              init.defaultBranch = "main";
              push.autoSetupRemote = true;
            };
          };
          programs.ssh = {
            enable = true;
            enableDefaultConfig = false;
            settings = {
              "github.com" = {
                HostName = "github.com";
                User = "git";
                IdentityFile = "~/.ssh/git_id_ed25519";
                IdentitiesOnly = true;
              };
            };
          };
          programs.vscode = {
            profiles.default = {
              enableUpdateCheck = false;
              enableExtensionUpdateCheck = false;
              extensions = with pkgs.vscode-extensions; [
                jnoortheen.nix-ide
                rust-lang.rust-analyzer
              ];
            };
            enable = true;
            argvSettings = {
              enable-crash-reporter = false;
            };
            mutableExtensionsDir = false;

            # user specific definitions are buggy on darwin.
            profiles.default.userSettings = {
              "[nix]" = {
                "editor.tabSize" = 2;
              };
              "files.autoSave" = "off";
              "nix.enableLanguageServer" = true;
              "nix.serverPath" = "nil";
              "update.mode" = "none";
            };
          };
          programs.direnv = {
            enable = true;
            enableZshIntegration = true; # Or enableZshIntegration / enableFishIntegration
            nix-direnv.enable = true;
          };
          programs.claude-code = {
            enable = true;
          };
          programs.tmux = {
            enable = true;
            extraConfig = ''
              set-option -g default-shell ${pkgs.zsh}/bin/zsh
            '';
          };
        })
      ]
    ) cfg.home;
  };
}

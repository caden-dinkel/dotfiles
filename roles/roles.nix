{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.roles;
  myHomeDir = if pkgs.stdenv.hostPlatform.isLinux then "/home/" else "/Users/";
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
  userOptType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.passwdEntry lib.types.str;
        apply =
          x:
          assert (
            lib.stringLength x < 32
            || abort "Username '${x}' is longer than 31 characters which is not allowed!"
          );
          x;
        description = ''
          The name of the user account to apply personal role to.
        '';
      };
      # Desktop environment
      environment = {
        yabai = {
          enable = lib.mkEnableOption ''
            Enable yabai window manager.
          '';
        };
        gnome = {
          enable = lib.mkEnableOption ''
            Enable gnome desktop environment.
          '';
        };
      };
      # Sub Roles
      roles = {
        dev = {
          enable = lib.mkEnableOption ''
            Enable development packages/environment for user.
          '';
          git = {
            name = lib.mkOption {

            };
            email = lib.mkOption {

            };
          };
        };
        home = {
          enable = lib.mkEnableOption ''
            Enable Home manager for user. 
            Note that some roles will apply this automatically.
          '';
        };

      };
    };
  };

in
{
  options.roles = {
    personal = {
      enable = lib.mkEnableOption ''
        Enable personal role for system.
        Requires a user account to be set.
      '';
      user = lib.mkOption {
        type = lib.types.nullOr userOptType;
        default = null;
        description = ''
          User account to which the personal role applies.
        '';
      };
    };
    server = {
      enable = lib.mkEnableOption ''
        Enable server role for a system.
      '';
      roles = {
        binary-cache = {
          enable = lib.mkEnableOption ''
            Enable binary cache on server.
          '';
        };
        minecraft = {
          enable = lib.mkEnableOption ''
            Enable minecraft server.
          '';
        };
      };
    };
  };

  config = lib.mkMerge [
    # I need to refactor modules to use options so I can import everything and selectively enable things.
    # or just put it here.
    (
      lib.mkIf cfg.personal.enable
      && cfg.personal.user.roles.home.enable {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "backup";
        home-manager.users.${cfg.personal.user.name} = {
          home.homeDirectory = myHomeDir + cfg.personal.user.name;
          home.stateVersion = "26.05";
          home.packages =
            with pkgs;
            [ ]
            ++ lib.optionals cfg.personal.user.roles.dev.enable [
              eza
              ripgrep
              helix
              dust
              pciutils
              nil
              nixfmt
            ];
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
          programs.direnv = lib.mkIf cfg.personal.user.roles.dev.enable {
      enable = true;
      enableZshIntegration = true; # Or enableZshIntegration / enableFishIntegration
      nix-direnv.enable = true;
    };
          programs.git = lib.mkIf cfg.personal.user.roles.dev.enable {
            enable = true;
            ignores = [ "**/.DS_Store" ];
            settings = {
              user = {
                name = cfg.personal.user.roles.dev.git.name;
                email = cfg.personal.user.roles.dev.git.email;
              };
              init.defaultBranch = "main";
              push.autoSetupRemote = true;
            };
          };
          programs.ssh = lib.mkIf cfg.personal.user.roles.dev.enable {
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
          programs.vscode = lib.mkIf cfg.personal.user.roles.dev.enable {
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

        };
      }
    )
    (lib.mkIf cfg.server.enable {
    })
  ];
}

{
  name,
  pkgs,
  git,
  ...
}:
let
  myHomeDir = if pkgs.stdenv.hostPlatform.isLinux then "/home/${name}" else "/Users/${name}";
in
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.users.${name} = {
    home.packages = [
      pkgs.tree
      pkgs.tmux
      pkgs.ripgrep
      pkgs.bitwarden-desktop
      pkgs.helix

      pkgs.nil
      pkgs.nixfmt
    ];
    home.homeDirectory = myHomeDir;
    home.stateVersion = "26.05";
    programs.git = {
      enable = true;
      ignores = [ "**/.DS_Store" ];
      settings = {
        user = {
          name = git.name;
          email = git.email;
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
      enable = true;
      argvSettings = {
        enable-crash-reporter = false;
      };
      mutableExtensionsDir = false;
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
      ];
      profiles.${name}.userSettings = {
        "[nix]" = {
          "editor.tabSize" = 2;
        };
        "files.autoSave" = "off";
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.formatterPath" = "nixfmt -";
      };
    };

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
    programs.claude-code = {
      enable = true;
    };
    programs.ncspot = {
      enable = true;
    };
    programs.obsidian = {
      enable = true;
    };
    programs.firefox = {
      enable = true;
    };
    programs.zsh = {
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
    programs.fzf = {
      enable = true;
    };
  };
}

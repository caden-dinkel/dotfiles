{pkgs,  git,
 ...}:{
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

}
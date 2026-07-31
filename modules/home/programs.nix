{ pkgs, ... }:

{
  home = {
    stateVersion = "26.05";
    packages = with pkgs; [
      bitwarden-cli
    ];
  };
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.obsidian = {
    enable = true;
  };

  # This isn't working properly. Need to look into it.
  programs.cursor = {
    enable = false;
    profiles.cdink = {
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
      ];
    };
  };
}

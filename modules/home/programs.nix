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
  programs.cursor = {
    enable = true;
    profiles.cdink = {
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
      ];
    };
  };
}

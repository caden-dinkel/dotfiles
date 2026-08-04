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
  programs.vscode = {
    enable = true;
  };
  programs.claude-code = {
    enable = true;
  };
}

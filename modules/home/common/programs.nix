{ pkgs, ... }:
{
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
  programs.ncspot = {
    enable = true;
  };
}
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
    profiles.cdink.extensions = [
      pkgs.vscode-extensions.jnoortheen.nix-ide
    ];
  };
}

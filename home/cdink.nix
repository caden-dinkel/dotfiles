{ pkgs, ... }:

{
  home = {
    stateVersion = "26.05";
    packages = with pkgs; [
      bitwarden-cli
    ];
    programs.wezterm = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}

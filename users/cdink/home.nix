{ config, pkgs, ... }:

{
  home.username = "cdink"";
  home.homeDirectory = "/home/cdink";

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}

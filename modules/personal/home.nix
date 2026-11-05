{ config, lib, pkgs, name, ... }:
let
  cfg = config.roles.personal.user.roles.home;
  myHomeDir = if pkgs.stdenv.hostPlatform.isLinux then "/home/${name}" else "/Users/${name}";
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
in
{
  config = lib.mkIf cfg.enable {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "backup";
    home-manager.users.${name} = {
      home.homeDirectory = myHomeDir;
      home.stateVersion = "26.05";
    };
  };
}
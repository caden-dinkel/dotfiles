{ config, lib, pkgs, name, ... }:
let
  cfg = config.roles.personal.user.roles.dev;

in
{
  config = lib.mkIf cfg.enable {
    home-manager.users.${name} = {
      home.packages = with pkgs; [
        eza
        ripgrep
        helix
        dust
        pciutils
        nil
        nixfmt
      ];
    };
  };
}
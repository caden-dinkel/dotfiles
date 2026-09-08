{ config, lib, pkgs, ... }:
let
    cfg = config.modules.audio;
in
{
    options.modules.audio = {
        enable = mkEnableOption "Enable pipewire audio control."
    };

    config = lib.mkIf cfg.enable {
        imports = [ ./pipewire.nix ];
    };
}
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystem.deploy;
in
{
  options.mySystem.deploy = {
    enable = lib.mkEnableOption "Enable managed deployment for this system.";
    deploy-rs = lib.mkOption {

    };
  };
  config = {

  };
}

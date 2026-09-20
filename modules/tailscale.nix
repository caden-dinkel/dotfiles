{
  appType,
  keyFilePath,
  config,
  lib,
  pkgs,
  ...
}:
if appType == "server" then
  {
    services.tailscale = {
      enable = true;
      authKeyFile = keyFilePath;
      # If deployment is planned through normal ssh, the port should be changed.
    };
  }
else
  {
    services.tailscale = lib.mkIf config.stdenv.hostPlatform.isLinux {
      enable = true;
    };

    environment.systemPackages = lib.mkIf config.stdenv.hostPlatform.isDarwin [
      pkgs.tailscale-gui
    ];
  }

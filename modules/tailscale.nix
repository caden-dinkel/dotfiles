{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myNetworking.tailscale;
in
{
  options.myNetworking.tailscale = {
    enable = lib.mkEnableOption "Enable tailscale.";
    profile = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "server"
          "personal"
        ]
      );
      default = null;
      description = ''
        Base profile to install tailscale with.
        "personal" prefers GUI clients and requires manual sign-in.
        "server" prefers cli clients and can utilize the authKeyFile.
      '';
    };
    authKeyFile = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.oneOf [
          lib.types.str
          lib.types.path
        ]
      );
      default = null;
      description = ''
        File location of authkey needed to connect to tailnet. Only valid for server profiles.
      '';
    };
    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Tailscale domain prefix to access tailnet.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment = lib.mkIf (cfg.profile == "personal" && pkgs.stdenv.hostPlatform.isDarwin) {
      systemPackages = [
        pkgs.tailscale-gui
      ];
    };

    services.tailscale = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      enable = true;

      # Nest the server-specific settings cleanly within the Linux block
      authKeyFile = if cfg.profile == "server" then cfg.authKeyFile else null;

      extraUpFlags =
        if cfg.profile == "server" then
          [
            "--ssh=false"
            "--advertised-tags=tag:provisioned-machine"
          ]
        else
          [ ];
    };
  };
}

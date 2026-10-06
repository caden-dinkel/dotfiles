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
    # In the future, I can make my own package abstraction, and place them accordingly in user/home locations.
    environment = lib.mkIf (cfg.profile == "personal" && pkgs.stdenv.hostPlatform.isDarwin) {
      systemPackages = [
        pkgs.tailscale-gui
      ];
    };

    services.tailscale =
      lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        enable = true;
      }
      // lib.optionalAttrs (cfg.profile == "server") {
        authKeyFile = cfg.authKeyFile;
      };
  };
}

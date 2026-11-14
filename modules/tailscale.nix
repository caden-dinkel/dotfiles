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

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # Personal profile on macOS
      (lib.mkIf (cfg.profile == "personal" && pkgs.stdenv.hostPlatform.isDarwin) {
        services.tailscale.enable = true;
      })

      # Server profile on Linux
      (lib.mkIf (cfg.profile == "server" && pkgs.stdenv.hostPlatform.isLinux) {
        networking.firewall.trustedInterfaces = [
          "tailscale0"
        ];
      })

      # All Linux profiles
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        services.tailscale = {
          enable = true;

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
      })
    ]
  );
}

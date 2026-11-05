{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.roles;
  userOptType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.passwdEntry lib.types.str;
        apply =
  x:
  assert (
    lib.stringLength x < 32
    || abort "Username '${x}' is longer than 31 characters which is not allowed!"
  );
  x;
        description = ''
          The name of the user account to apply personal role to.
        '';
      };
      # Desktop environment
      environment = lib.mkOption {
        type =
          if pkgs.stdenv.hostPlatform.isDarwin then
            lib.types.enum [ "yabai" ]
          else
            lib.types.enum [ "gnome" ];
        default = if pkgs.stdenv.hostPlatform.isDarwin then "yabai" else "gnome";
        example = "gnome";
        description = ''
          Desktop environment to be used for a given user.
        '';
      };
      # Sub Roles
      roles = {
        dev = {
          enable = lib.mkEnableOption ''
            Enable development packages/environment for user.
          '';
        };
        home = {
          enable = lib.mkEnableOption ''
            Enable Home manager for user. 
            Note that some roles will apply this automatically.
          '';
        };
        
      };
    };
  };

in
{
  options.roles = {
    personal = {
      enable = lib.mkEnableOption ''
        Enable personal role for system.
        Requires a user account to be set.
      '';
      user = lib.mkOption {
  type = lib.types.nullOr userOptType;
  default = null;
  description = ''
    User account to which the personal role applies.
  '';
};
    };
    server = {
      enable = lib.mkEnableOption ''
        Enable server role for a system.
      '';
      roles = lib.mkOption {
        type = lib.types.listOf (
          lib.types.enum [
            "minecraft"
            "binary-cache"
          ]
        );
        default = [ ];
      };
    };
  };
  assertions = [
  {
    assertion = !cfg.personal.enable || cfg.personal.user != null;
    message = "The personal role requires a user to be configured.";
  }
];
  config = lib.mkMerge [
    # I need to refactor modules to use options so I can import everything and selectively enable things.
    # or just put it here.
    (lib.mkIf cfg.personal.enable {
      services = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        yabai = lib.mkIf cfg.personal.user.environment == "yabai" {

        };
      };
    })
    (lib.mkIf cfg.server.enable {
    })
  ];
}

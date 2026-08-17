{ self, pkgs, lib, ... }:
let
  userName = "cdink";
  userDescription = "Caden Dinkel";
in
{
  # Note: Pulling this user will automatically pull in the home-manager profile and the software it contains.
  imports = [
    "${self}/modules/home"

    {
      _module.args = { inherit userName; };
    }
  ];

  users.users."${userName}" = {
    description = userDescription;

    home = if pkgs.stdenv.isDarwin then "/Users/${userName}" else "/home/${userName}";

    packages = [
      pkgs.helix
    ];

  } // lib.mkIf pkgs.stdenv.isLinux {
    createHome = true;

    isNormaluser = true;

    extraGroups = [
      "wheel"
      "networkmanager" 
      "bluetooth" 
    ];

    shell = pkgs.zsh;
  };
}

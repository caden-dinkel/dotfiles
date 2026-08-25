{ self, pkgs, lib, username, userDescription, ... }:
{
  users.users."${username}" = {
    description = userDescription;

    home = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${username}" else "/home/${username}";

    packages = [
      pkgs.helix
    ];

  } // lib.mkIf pkgs.stdenv.isLinux {
    createHome = true;

    isNormalUser = true;

    extraGroups = [
      "wheel"
      "networkmanager" 
      "bluetooth" 
    ];

    shell = pkgs.zsh;
  };
} // lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  system.primaryUser = username;
}

{ pkgs, ... }:
{
  system.stateVersion = if pkgs.stdenv.hostPlatform.isDarwin then 6 else "26.05";
}
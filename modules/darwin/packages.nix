{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.vfkit
  ];
}
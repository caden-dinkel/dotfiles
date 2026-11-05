{ pkgs, ... }:
let
  hasPkg = pkgs ? darwin.linux-builder-vz;
  myPkg = if hasPkg then pkgs.darwin.linux-builder-vs else pkgs.darwin.linux-builder;
in
{
  nix.linux-builder = {
    enable = true;
    package = myPkg;
    systems = [
      "aarch64-linux"
      "x86_64-linux"
    ];

    ephemeral = true;
    maxJobs = 4;
    config = {
      virtualisation = {
        darwin-builder = {
          diskSize = 40 * 1024;
          memorySize = 8 * 1024;
        };
        cores = 6;
      };
    };
  };
}

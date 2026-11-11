{ lib, host, isVm ? false, ... }:
let
  hosts = {
    alpha = {
      platform = "aarch64-darwin";
      hardware = ../../profiles/macbook.nix;
      software = ./alpha;
    };
    bravo = {
      platform = "x86_64-linux";
      hardware = ../../profiles/desktop.nix;
      software = ./bravo;
    };
    charlie = {
      platform= "x86_64-linux";
      hardware = ../../profiles/omen.nix;
      software = ./charlie;
    };
  };
  vmHardware = ../../profiles/vm.nix;
  selectedHost = hosts.${host} or (throw "Unknown host: ${host}");
in
{
  imports = [
    selectedHost.software
  ] ++ lib.optionals (!isVm) [
    selectedHost.hardware
  ] ++ lib.optionals isVm [
    vmHardware
  ];
}
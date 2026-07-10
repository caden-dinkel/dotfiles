{ self, pkgs, inputs, ... }:
{
    imports = [
        inputs.microvm.nixosModules.microvm
        ./microvm.nix
    ];
}
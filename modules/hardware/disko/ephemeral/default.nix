{
    imports = [
        inputs.impermanence.nixosModules.impermanence
        ./persist.nix
        ./rollback.nix
    ];
}
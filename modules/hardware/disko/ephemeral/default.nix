# Note that tailscale.nix is currently a dependency of ephemeral activation.
{
    imports = [
        inputs.impermanence.nixosModules.impermanence
        ./persist.nix
        ./rollback.nix
    ];
}
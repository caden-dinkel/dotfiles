# Note that tailscale.nix is currently a dependency of ephemeral activation.
{ inputs, ... }:
{
    imports = [
        inputs.impermanence.nixosModules.impermanence
        ./persist.nix
        ./rollback.nix
    ];
}
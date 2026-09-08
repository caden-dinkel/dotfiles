{ platform, ... }:
{
    system.stateVersion = import ./${platform}.nix;
}
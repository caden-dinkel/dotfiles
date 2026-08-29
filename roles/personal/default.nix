{ platform, ... }:
[
    ./common.nix

    (./platform + "/${platform}.nix")
]
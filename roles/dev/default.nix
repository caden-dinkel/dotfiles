{ platform, ... }:
[
    ./common.nix

    (./platform + "/${config.mySystem.platform}.nix")
]
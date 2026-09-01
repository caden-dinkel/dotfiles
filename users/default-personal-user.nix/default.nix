{ platform, ... }:
let

in
[
    ./common.nix
    ./platform + "/${platform}.nix"
]
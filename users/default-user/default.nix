{ platform, user, ... }:
[
    ./user.nix { inherit user; }
    (./ + "${platform}.nix")
]
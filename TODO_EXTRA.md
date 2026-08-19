# Additional TODOs

Items missing from TODO that should be addressed before this is in a decent working state.

---

[ ] - Create actual SOPS secrets. `.sops.yaml` and the darwin sops module are wired up but there's no `secrets/` directory and no secrets files. The Tailscale auth key is the obvious first candidate (would replace the Bitwarden fetch in `anywhere-omen.sh`). Requires deciding which hosts need access to which secrets and updating `.sops.yaml` creation_rules accordingly.

[X] - Make the deploy user's `nix-env` sudo rule more robust. The current rule pins to `${pkgs.nix}/bin/nix-env` which is a specific store path. Consider using a glob pattern or `/run/current-system/sw/bin/nix-env` so it doesn't break silently on nix upgrades.

[ ] - Add a `secrets/` directory with a `.gitkeep` or first real secret so the path structure matches `.sops.yaml` expectations.

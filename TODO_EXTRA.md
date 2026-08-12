# Additional TODOs

Items missing from TODO that should be addressed before this is in a decent working state.

---

[ ] - Fix `anywhere-omen.sh` — the script has a bash syntax error (`end` instead of `;;` on line 15), all three argument assignments capture the flag name instead of the value (`$1` instead of `$2`), and the target IP variable is parsed but never used (line 38 has it hardcoded to `192.168.1.232`). The `$BW_SESSION` dependency is also implicit and unchecked.

[ ] - Generate a real `hardware-configuration.nix` for omen. The current file is a placeholder (`{}`). Requires the provisioning script above to work first, or manual generation by booting a NixOS installer on omen and running `nixos-generate-config`.

[ ] - Fix networking in `base.nix`. The current config enables iwd and defines a `wlan0` systemd-network rule, but omen is a desktop and almost certainly uses ethernet. At minimum, add an ethernet network config (e.g., `matchConfig.Name = "en*"` or specific interface). Also decide: NetworkManager vs systemd-networkd. Currently NM system-connections is persisted but NM is not enabled anywhere.

[ ] - Create actual SOPS secrets. `.sops.yaml` and the darwin sops module are wired up but there's no `secrets/` directory and no secrets files. The Tailscale auth key is the obvious first candidate (would replace the Bitwarden fetch in `anywhere-omen.sh`). Requires deciding which hosts need access to which secrets and updating `.sops.yaml` creation_rules accordingly.

[ ] - Add NixOS host age key to sops. The NixOS host needs an age key derived from its SSH host key so it can decrypt secrets at activation. Currently only the mac age key is in `.sops.yaml`. Once omen's SSH host key is known (after first provisioning), add it to `.sops.yaml` and re-encrypt any shared secrets.

[ ] - Wire up ethernet for omen in `base.nix` or make the network config host-specific via a module option. The wlan0 config should either be behind a `mkIf` or moved to a separate wifi module that omen doesn't import.

[ ] - Remove unused `microvm` input from flake outputs until it's actually used, or wire it up as a `specialArg` if the linux-builder work is starting. Dead inputs still get fetched and add to lock file churn.

[ ] - Decide on a strategy for x86_64-linux builds from darwin. The current linux-builder only does `aarch64-linux`. Deploying to omen from the mac requires either omen to build locally, a remote x86_64 builder in `nix.buildMachines`, or build on a shared cache. This should be resolved before relying on the deploy workflow regularly.

[ ] - Add Apple Watch auth to `pam.nix` once the watch is set up (`watchIdAuth = true; reattach = true;`).

[ ] - Make the deploy user's `nix-env` sudo rule more robust. The current rule pins to `${pkgs.nix}/bin/nix-env` which is a specific store path. Consider using a glob pattern or `/run/current-system/sw/bin/nix-env` so it doesn't break silently on nix upgrades.

[ ] - Add a `secrets/` directory with a `.gitkeep` or first real secret so the path structure matches `.sops.yaml` expectations.

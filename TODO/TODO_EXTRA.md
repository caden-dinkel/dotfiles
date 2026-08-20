# Additional TODOs

Items missing from TODO that should be addressed before this is in a decent working state.

---

## Evaluation-Breaking Bugs (Nothing Builds Until These Are Fixed)

[X] - `users/default.nix` is missing `in` between the `let` block and the body attrset. Parse error.

[X] - `modules/desktop/default.nix` references `lib` but does not declare it in function args. Fix: `{ pkgs, lib, ... }:`.

[X] - `modules/desktop/common/fonts.nix` references `pkgs` with no function args at all. Needs `{ pkgs, ... }:` added.

[X] - `modules/desktop/linux/system.nix` references `pkgs` with no function args. Needs `{ pkgs, ... }:`. Also ends with `};` (trailing semicolon at file level — syntax error).

[X] - `modules/desktop/linux/services.nix` is missing a semicolon after the greetd `command` value. Also ends with `};` (same trailing semicolon issue).

[X] - `hosts/bravo/default.nix` imports `${self}/metadata/linux-x86_64.nix` which does not exist. The file is `metadata/nixos-x86_64.nix`.

[X] - `inputs` is not passed in `specialArgs` (only `self` is). Four modules fail because of this: `modules/hardware/disko/default.nix`, `modules/hardware/disko/ephemeral/default.nix`, `modules/home/default.nix`, `modules/software/sops/default.nix`. Fix: add `inputs = self.inputs;` to `specialArgs` in both `nixosSystem` and `darwinSystem` calls in `flake.nix`.

[X] - `flake.nix` `getMeta` function does `import ./hosts/${name}/metadata.nix` but those files are module functions (`{ self, ... }:`), not plain attrsets. Accessing `.type` or `.deployable` on a function throws an error. Either make host `metadata.nix` files plain attrsets (no function wrapper), or restructure so `getMeta` reads from a separate flat file per host.

[X] - `modules/hardware/disko/disko.nix` imports `inputs.impermanence.nixosModule.impermanence` (singular) — wrong path. Should be `inputs.impermanence.nixosModules.impermanence` (plural). Also, both `disko.nix` and `ephemeral/default.nix` import impermanence independently — one of them should be removed.

---

## Logic / Design Fixes

[ ] - `modules/software/tailscale.nix` (the complete tailscale module with auth key handling, firewall rules, and clear-after-boot service) is never imported anywhere. Wire it into `roles/server.nix` or a suitable module and remove the bare `services.tailscale.enable = true` from `modules/common/services.nix`.

[ ] - `profiles/omen-laptop/configuration.nix` uses wrong option names for both the nvidia and disko modules. The module API uses `myHardware.disk.main.device`, `myHardware.disk.main.swap.size`, `myHardware.disk.secondary.enable`, `myHardware.disk.secondary.device` — not `mainDevice`, `swapSize`, `enableSecondary`, `secondaryDevice`. The nvidia module also does not have a `prime` option; that reference should be removed.

[ ] - `modules/apps/provision.nix` references `nixpkgs` and `nixos-anywhere` as if they're flake-level variables, but it's a module file — those are out of scope. Also, `nixos-anywhere` is not a flake input. Either move the provision app logic into `flake.nix` outputs directly, or restructure how the file is imported. Add `nixos-anywhere` as a flake input when implementing.

[X] - `modules/home/linux/services.nix` declares `services.awww` which is not a real home-manager service. This is almost certainly a typo for `swww` (the Wayland wallpaper daemon). Confirm the correct home-manager module name and fix.

changed name from swww to awww.

[ ] - `EXTRAFILES/sops.nix` (which sets `sops.age.keyFile`) is outside the module tree and not imported anywhere. Move its content into `modules/software/sops/sops.nix` which is currently empty.

[X] - Add a `monitoring` user module. `users/registry.nix` allocates UID 903 for `monitoring` but no user is defined or imported in `users/default.nix`.

[ ] - `modules/home/common/hotkeys/` is all stubs. Implement the terminal open hotkey in `open-term.nix` and import it in `hotkeys/default.nix`. Then import `hotkeys` in `modules/home/common/default.nix`. (The skhd keybind in `skhd.nix` is commented out pending this.)

---

## Security

[ ] - Deploy and admin SSH keys are the same key (`mac@cdink.dev`). These should be separate keys. A compromised deploy key should not grant admin-equivalent access.

[ ] - `users/admin.nix` declares `isSystemUser = true` with no shell, which defeats the purpose of an emergency access user. Either switch to `isNormalUser = true` with a locked password and a real shell, or rethink what "emergency access" means here.

[ ] - `git.nix` gitignore has `**/.DS_STORE` (all caps) but the actual macOS file is `.DS_Store` (mixed case). On case-sensitive filesystems this never matches. Fix the case.

---

## Missing Flake Outputs / Infrastructure

[ ] - Add `deploy-rs` checks output to `flake.nix` so `nix flake check` validates deployment configs:
  ```nix
  checks = builtins.mapAttrs (_: lib: lib.deployChecks self.deploy) deploy-rs.lib;
  ```

[ ] - Add a `devShells` output that provides a shell with `deploy-rs`, `nixos-anywhere`, `sops`, and `age` pinned to the flake's nixpkgs. Avoids tool/version drift between the shell and the deployed systems.

[ ] - Add `nixos-anywhere` as a flake input (needed for `provision.nix` and the provisioning workflow described in `NOTES`).

[ ] - Hardcoded Tailscale domain `rainbow-dorian.ts.net` in `flake.nix` should be a variable or pulled from per-host metadata so renaming the tailnet doesn't require editing the flake core.

[ ] - `modules/common/system.nix` sets `networking.dns = []` — an explicit empty list. Verify this is intentional and not accidentally overriding upstream defaults. On NixOS, `networking.nameservers` (set in `modules/linux/system.nix`) is the right knob; the `networking.dns` option may not do anything useful or may conflict.

[ ] - Wire up the `provision.nix` app properly under `flake.outputs.apps` once the module is fixed.


## Breaking / Must Fix

[ ] - Fix deploy user to have proper NOPASSWD for correct commands.

[ ] - Fix application of inputs to systems that utilize them.

---

## Security

[ ] - Create actual SOPS secrets. `.sops.yaml` and the darwin sops module are wired up but there's no `secrets/` directory and no secrets files. The Tailscale auth key is the obvious first candidate (would replace the Bitwarden fetch in `anywhere-omen.sh`). Requires deciding which hosts need access to which secrets and updating `.sops.yaml` creation_rules accordingly.

[ ] - Add a `secrets/` directory with a `.gitkeep` or first real secret so the path structure matches `.sops.yaml` expectations.

[ ] - Deploy and admin SSH keys are the same key (`mac@cdink.dev`). These should be separate keys. A compromised deploy key should not grant admin-equivalent access.

[ ] - `users/admin.nix` declares `isSystemUser = true` with no shell, which defeats the purpose of an emergency access user. Either switch to `isNormalUser = true` with a locked password and a real shell, or rethink what "emergency access" means here.

[ ] - `git.nix` gitignore has `**/.DS_STORE` (all caps) but the actual macOS file is `.DS_Store` (mixed case). On case-sensitive filesystems this never matches. Fix the case.


---

## Core Infrastructure

[ ] - Move anywhere-omen.sh into the flake properly, and finish it to generate/configure age keys. -> modules/provision.nix

[ ] - modules/scripts/provision.nix is empty. Implement provisioning logic to replace anywhere-omen.sh as a flake app (see existing TODO and NOTES).

[ ] - Add proper top level apps output. I think I just need to wrap apps dir with some magic.

[ ] - `EXTRAFILES/sops.nix` (which sets `sops.age.keyFile`) is outside the module tree and not imported anywhere. Move its content into `modules/software/sops/sops.nix` which is currently empty.

[ ] - Add `nixos-anywhere` as a flake input (needed for `provision.nix` and the provisioning workflow described in `NOTES`).

[ ] - Hardcoded Tailscale domain `rainbow-dorian.ts.net` in `flake.nix` should be a variable or pulled from per-host metadata so renaming the tailnet doesn't require editing the flake core.

[ ] - `modules/common/system.nix` sets `networking.dns = []` — an explicit empty list. Verify this is intentional and not accidentally overriding upstream defaults. On NixOS, `networking.nameservers` (set in `modules/linux/system.nix`) is the right knob; the `networking.dns` option may not do anything useful or may conflict.

[ ] - Wire up the `provision.nix` app properly under `flake.outputs.apps` once the module is fixed.

---

## Feature Implementation

[ ] - Configure linux desktop environment services/programs.

[ ] - `modules/home/common/hotkeys/` is all stubs. Implement the terminal open hotkey in `open-term.nix` and import it in `hotkeys/default.nix`. Then import `hotkeys` in `modules/home/common/default.nix`. (The skhd keybind in `skhd.nix` is commented out pending this.)

---

## Tooling / Developer Experience

[ ] - add treefmt-nix and setup some formatting for different languages.

[ ] - Add a `devShells` output that provides a shell with `deploy-rs`, `nixos-anywhere`, `sops`, and `age` pinned to the flake's nixpkgs. Avoids tool/version drift between the shell and the deployed systems.

---

## Future

[ ] - Ephemeral CI/CD runner. I should be able to design something based on nix flakes/microvm fairly easily.

[ ] - Microvm based kubernetes simulation for dev environments.

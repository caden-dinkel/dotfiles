# Flake Review

## Overview

The architecture is well-conceived. The layered model — `hosts` → `profiles` → `roles` → `modules/users` — is clean and scales naturally. The automated host enumeration in `flake.nix` via `builtins.readDir` avoids repetitive per-host boilerplate. The metadata pattern for separating build-time properties (`system`, `type`, `deployable`) from NixOS module config is a good instinct. The disko module with proper NixOS option declarations, assertions, and ephemeral/non-ephemeral branching is legitimately well done. The general direction is solid.

That said, there are enough evaluation-breaking bugs that this flake almost certainly cannot be built as-is. The rest of this document organizes everything found.

---

## Critical Bugs (Prevent Evaluation)

### 1. `users/default.nix` — Missing `in` keyword

```nix
let
    registry = import ./registry.nix;
    mkUser = userName: userModule: { ... };
{   # <-- should be `in {`
```

The `let` block is never closed with `in`. This is a parse error.

DONE

### 2. `modules/desktop/default.nix` — `lib` not in function args

```nix
{ pkgs, ... }:   # lib missing
{
    imports = [ ./common ] ++ lib.optionals ...
```

`lib` is referenced but not destructured. Fails at evaluation. Fix: `{ pkgs, lib, ... }:`.

DONE

### 3. `modules/desktop/common/fonts.nix` — `pkgs` not in function args

The file is a bare attrset `{ fonts.packages = [ pkgs.nerd-fonts.hack ... ]; }` with no function args. `pkgs` is undefined.

DONE

### 4. `modules/desktop/linux/system.nix` — `pkgs` not in function args

Same issue. `xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ... ]` with no `pkgs` in scope. File also ends with `};` — the trailing `;` at file level is a syntax error.

DONE

### 5. `modules/desktop/linux/services.nix` — Missing semicolon + trailing `};`

```nix
command = "${pkgs.tuigreet}/bin/tuigreet --cmd Hyprland"
# ^ no semicolon, parse error
```

File also ends with `};` — same trailing `;` issue as above.

### 6. `hosts/bravo/default.nix` — Imports non-existent metadata file

```nix
"${self}/metadata/linux-x86_64.nix"  # does not exist
```

The actual file is `metadata/nixos-x86_64.nix`. This is a file-not-found error at evaluation time.

### 7. `inputs` used but never passed in `specialArgs`

`flake.nix` passes `specialArgs = { inherit self; }` to both `nixosSystem` and `darwinSystem`. But several modules reference `inputs` directly:

- `modules/hardware/disko/default.nix` — `inputs.disko.nixosModules.disko`
- `modules/hardware/disko/ephemeral/default.nix` — `inputs.impermanence.nixosModules.impermanence`
- `modules/home/default.nix` — `inputs.home-manager.${systemModules}.home-manager`
- `modules/software/sops/default.nix` — `inputs.sops-nix.${systemModules}.sops`

None of these can evaluate. Fix: add `inputs = self.inputs;` to `specialArgs` in `flake.nix`.

### 8. `flake.nix` `getMeta` function — Returns a function, not an attrset

```nix
getMeta = name: import ./hosts/${name}/metadata.nix;
```

Each `hosts/${name}/metadata.nix` is a *module function* (`{ self, ... }: { imports = [...]; }`). `import` returns the function itself. Then:

```nix
(getMeta name).type        # accessing .type on a lambda → error
(getMeta name).deployable  # same
```

Nix will throw "cannot select from a function" here. The metadata files need to either be plain attrsets (not modules), or `getMeta` needs a different lookup strategy (e.g. reading from a separate top-level `meta.nix` per host).

### 9. `modules/hardware/disko/disko.nix` — Wrong impermanence module path

```nix
inputs.impermanence.nixosModule.impermanence  # singular — wrong
```

The correct path is `inputs.impermanence.nixosModules.impermanence` (plural). The `ephemeral/default.nix` has it right; `disko.nix` has a typo. Additionally, both `disko.nix` and `ephemeral/default.nix` try to import impermanence, which is a double import.

---

## Logic / Design Bugs

### 10. `modules/software/tailscale.nix` is dead code

The complete tailscale module (auth key handling, firewall rules, clear-after-boot service) is never imported anywhere. `modules/common/services.nix` only has the bare `services.tailscale.enable = true`. The sophisticated module at `modules/software/tailscale.nix` isn't wired up to any role, profile, or module default.

### 11. `profiles/omen-laptop/configuration.nix` uses wrong option names

The profile sets:
```nix
myHardware = {
    nvidia.prime.enable = false;   # prime is not an option in nvidia.nix
    disk.mainDevice = "/dev/nvme0n1";  # wrong; actual option is disk.main.device
    disk.enableSecondary = true;   # wrong; actual option is disk.secondary.enable
    disk.secondaryDevice = "/dev/sda"; # wrong; actual option is disk.secondary.device
    disk.swapSize = "16G";         # wrong; actual option is disk.main.swap.size
};
```

The module definitions in `modules/hardware/nvidia.nix` and `modules/hardware/disko/disko.nix` have different option paths than what the profile sets. The profile is out of sync with the module API.

### 12. `modules/apps/provision.nix` is broken and unwired

The file references `nixpkgs` and `nixos-anywhere` as if they're in scope, but they aren't — it's a module file, not a flake output expression. `nixos-anywhere` is also not a flake input at all. The file also doesn't match the expected structure for `flake.outputs.apps`. It's currently unreachable dead code.

### 13. Metadata files used inconsistently

The top-level `metadata/` files (e.g. `metadata/nixos-x86_64.nix` returning `{ system = "x86_64-linux"; type = "nixos"; }`) serve dual roles:
- Consumed as plain Nix attrsets by `getMeta` in `flake.nix`
- Imported as NixOS modules in host `default.nix` files (via `metadata.nix` → imports)

When used as NixOS modules, `system` and `type` are not valid NixOS options, so those imports do nothing useful and will produce warnings or errors depending on evaluation strictness.

### 14. `users/default.nix` doesn't include the `monitoring` user

`users/registry.nix` has a UID for `monitoring` (903), but `users/default.nix` never defines or imports a monitoring user module. The UID allocation is orphaned.

### 15. `modules/home/common/hotkeys/` is completely empty

`hotkeys/default.nix` only contains empty `imports = []` and `open-term.nix` is `{}`. The skhd config in `modules/desktop/darwin/services/skhd.nix` has the hotkey config commented out because it needs the home-manager user path. The hotkeys directory is a stub with no implementation.

### 16. `EXTRAFILES/sops.nix` is outside the module tree

The age key file config lives at `EXTRAFILES/sops.nix` but is not imported by `modules/software/sops/sops.nix` (which is empty) or anywhere else. It's unreachable. It should be moved into `modules/software/sops/sops.nix`.

### 17. `modules/home/linux/services.nix` — `services.awww` does not exist

`awww` is not a real home-manager service. The intended service is almost certainly `swww` (the Wayland wallpaper daemon). This would cause an evaluation error.

awww is the new name for swww.

---

## Security Observations

### 18. Deploy and admin SSH keys are identical

Both `users/admin.nix` and `users/deploy.nix` use the same public key (`mac@cdink.dev`). Admin has `NOPASSWD ALL` sudo. If the deploy key is compromised, an attacker gets full root. These should be separate keys with separate threat models.

### 19. `admin` is a system user with full passwordless sudo and no shell

`isSystemUser = true` means no home directory and no shell by default. As an "emergency user," this defeats the purpose. Either make it a normal user (with a proper shell and disabled password), or rethink the emergency access model.

### 20. Tailscale domain hardcoded in `flake.nix`

```nix
hostname = "${name}.rainbow-dorian.ts.net";
```

This should be a variable or pulled from per-host metadata so it can be changed without touching the flake core.

### 21. `git.nix` gitignore pattern has wrong case

```nix
ignores = [ "**/.DS_STORE" ];
```

The actual macOS file is `.DS_Store` (mixed case). On case-sensitive filesystems (Linux, most CI environments), this pattern won't match. Should be `.DS_Store`.

---

## Incomplete / Placeholder Code

- `modules/software/sops/sops.nix` — empty body
- `modules/home/common/hotkeys/default.nix` — empty imports
- `modules/home/common/hotkeys/open-term.nix` — empty attrset
- `modules/apps/provision.nix` — stub with non-functional code
- `modules/common/system.nix` — `networking.dns = []` sets DNS to empty list, which may override systemd-resolved defaults unintentionally
- `modules/desktop/darwin/services/skhd.nix` — keybind is commented out entirely; skhd is running but does nothing

---

## Missing Flake Outputs

- No `checks` output — deploy-rs recommends `checks = nixpkgs.lib.mapAttrs (_: deployChecks) deploy-rs.lib` to validate deployment configs at `nix flake check` time
- No `devShells` output — useful for pinning tools (nixos-anywhere, sops, deploy-rs CLI) to the same nixpkgs as the systems
- No `nixos-anywhere` input — referenced in `provision.nix` but absent from `flake.nix`
- `packages` output for `provision.nix` app is not wired up

---

## What's Actually Well Done

- **Automated host enumeration** — `builtins.readDir` + `filterAttrs` in `flake.nix` means adding a new host is just creating a directory. Clean.
- **Disko module design** — the NixOS option declarations with assertions, the ephemeral/non-ephemeral branching on `cfg.main.ephemeral`, and the rollback initrd script are genuinely solid.
- **Ephemeral root setup** — the rollback → persist pattern (delete root, snapshot from blank, mount persist) is correct and well thought out.
- **Separation of uid allocation** — `users/registry.nix` as a single source of truth for UIDs across all hosts is smart.
- **Deploy user sudo rules** — scoping to `switch-to-configuration switch` and `/run/current-system/sw/bin/nix-env` is appropriately minimal (the commented-out Reddit version is a reasonable backup reference).
- **Linux networking** — using `systemd.network` (networkd) with `networking.useDHCP = false` is the right modern choice. The wildcard `en* eth*` match is practical.
- **Tailscale auth key clear** — the `remove-tailscale-authkey` oneshot service to zero the key file after registration is a good security practice.
- **sops-nix Darwin/Linux dispatch** — `if pkgs.stdenv.isLinux then "nixosModules" else "darwinModules"` is the right way to handle it.
- **`system.primaryUser`** — correctly set via `lib.mkIf pkgs.stdenv.isDarwin` in `cdink.nix`.
- **`useGlobalPkgs = true; useUserPackages = true`** in home-manager config — correct and avoids double nixpkgs evaluation.

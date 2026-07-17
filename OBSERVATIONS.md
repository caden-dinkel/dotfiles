# Omen Host & Module Sanity Check

Reviewed: 2026-07-17

## Executive Summary

The **design direction is sound**: an ephemeral NixOS host with `/` on tmpfs, `/nix` on NVMe, state on a secondary disk, PRIME hybrid graphics, Tailscale for remote access, and a `deploy` user for deploy-rs. That matches established patterns (disko hybrid-tmpfs, impermanence-style bind mounts).

**It is not yet feasible to build or deploy as-is.** The omen host is not wired into `flake.nix`, module import paths are wrong, several modules will fail evaluation, and `hardware-configuration.nix` describes a different (non-ephemeral) layout than the disko module.

---

## Flake & Host Integration

| Issue | Severity | Notes |
|-------|----------|-------|
| No `nixosConfigurations` in `flake.nix` | **Blocker** | Only `darwinConfigurations."mac-m3"` exists. Omen cannot be built with `nix build` or deployed. |
| No `disko` flake input | **Blocker** | `modules/disko/disko.nix` sets `disko.devices` but nothing imports `disko.nixosModules.disko`. |
| Wrong import paths in `hosts/omen/configuration.nix` | **Blocker** | Imports `${self}/modules/nvidia.nix`, `disko.nix`, `tailscale.nix` — actual files live under `modules/{nvidia,disko,tailscale}/*.nix`. |
| No `nixpkgs.config.allowUnfree` on omen | **Blocker** | NVIDIA drivers are unfree; build will fail without this (darwin host already sets it). |
| No sops-nix module on omen | **High** | Tailscale `authKeyFile` and deploy secrets have no provisioning path yet (matches open TODO). |
| Hostname mismatch | **Low** | Directory is `hosts/omen` but `networking.hostName = "luck"`. |
| `system.stateVersion = "26.05"` | **Low** | Plausible for mid-2026 nixpkgs-unstable, but verify against target channel at deploy time. |

### Minimum wiring to unblock

1. Add `disko` (and likely `deploy-rs`) to flake inputs.
2. Add `nixosConfigurations.omen` (or `.luck`) importing disko, omen config, and modules.
3. Fix import paths to the nested module files.
4. Add `nixpkgs.config.allowUnfree = true` to the NixOS config.

---

## `modules/disko/disko.nix`

### What looks good

- Option schema (`myHardware.storage`) is clear and host-configurable.
- Assertions guard null `device` values when sub-options are enabled.
- Layout matches [disko's hybrid-tmpfs example](https://github.com/nix-community/disko/blob/master/example/hybrid-tmpfs-on-root.nix): ESP + swap + `/nix` on main disk, `/persistent` on secondary, `nodev."/"` tmpfs root.
- Pairing with omen's `persistentDirectories` (`/var/lib/tailscale`, `/etc/machine-id`, `/etc/ssh`) is the right idea for Tailscale + SSH identity across reboots.
- Swap with `resumeDevice = true` and `discardPolicy = "both"` is reasonable for a laptop.

### Issues

| Issue | Severity | Notes |
|-------|----------|-------|
| Module does not import disko | **Blocker** | Must `imports = [ disko.nixosModules.disko ]` (via flake input) in this module or the host. |
| ESP `extraArgs = [ "-O" "neededForBoot" ]` | **Bug** | `extraArgs` are passed to `mkfs`, not mount. `neededForBoot` is a NixOS `fileSystems.*` attribute, not a vfat format flag. Use `mountOptions` (e.g. `"umask=0077"`) instead; set `neededForBoot` via generated `fileSystems` if required. |
| Incomplete bind-mount setup | **High** | `systemd.tmpfiles.rules` only creates directories under `/persistent/...`. Bind mounts also require the **target** paths on the tmpfs root (e.g. `d /var/lib/tailscale 0755 root root -`) to exist before mount. Without these, boot will fail or mounts will misbehave. |
| Weak ephemeral assertion | **Medium** | `ephemeral -> (main \|\| persistent)` allows ephemeral with only `main` enabled, but all `persistentDirectories` bind to `/persistent${dir}`. Ephemeral use should assert `persistent.enable` when `persistentDirectories != []`. |
| No install-time mount strategy | **Medium** | For nixos-anywhere/disko-install, `/nix` on a separate partition works cleanly (disko example pattern). If you later move `/nix` onto the persistent disk with bind mounts, you'll hit [disko impermanence install edge cases](https://github.com/nix-community/disko/issues/718). Current layout avoids that. |
| Consider impermanence module | **Low** | Manual bind mounts work, but [nix-community/impermanence](https://github.com/nix-community/impermanence) handles tmpfiles, parent dirs, and permissions more robustly than hand-rolled rules. |

---

## `modules/nvidia/nvidia.nix`

### What looks good

- Standard PRIME offload wiring: `hardware.nvidia.prime.offload`, bus IDs passed through options.
- `modesetting` + `nvidia` video drivers, nouveau blacklisted, `modesetting.enable = true`.
- `legacy_580` exists in current nixpkgs-unstable (`nvidiaPackages.legacy_580` confirmed).

### Issues

| Issue | Severity | Notes |
|-------|----------|-------|
| Missing `allowUnfree` at host level | **Blocker** | See flake section. |
| Bus IDs unverified | **High** | `PCI:0:2:0` / `PCI:1:0:0` must match actual hardware (`lspci \| grep VGA`). Wrong IDs = no display or broken offload. |
| `services.xserver.videoDrivers` without explicit xserver enable | **Medium** | May still work via `hardware.graphics` on recent NixOS, but worth validating on target version. Headless/server use could drop xserver entirely. |
| No power-management options | **Low** | Laptop may benefit from `hardware.nvidia.powerManagement.enable` and/or `hardware.nvidia.prime.sync.enable` depending on whether you want Intel-only, NVIDIA-only, or offload-only. |

---

## `modules/tailscale/tailscale.nix`

### What looks good

- Minimal and correct for a module: `services.tailscale.enable = true`.
- `authKeyFile` path aligns with omen's `persistentDirectories` entry for `/var/lib/tailscale`.

### Issues

| Issue | Severity | Notes |
|-------|----------|-------|
| Auth key provisioning undefined | **High** | File `/var/lib/tailscale/ts-auth-key` must exist before first `tailscaled` start. sops-nix (TODO) or a one-time provisioning step is required. |
| Tagged one-time keys not configured | **Medium** | Matches TODO; module itself doesn't enforce key type or expiry. |
| Depends on disko bind-mount correctness | **High** | Tailscale state persistence only works if `/var/lib/tailscale` bind mount succeeds (see disko issues above). |

---

## `modules/users/deploy.nix`

| Issue | Severity | Notes |
|-------|----------|-------|
| `pkgs` used but not in module args | **Blocker** | `"${pkgs.nix}/bin/nix-env"` will fail — module signature is `{ ... }:` with no `pkgs`. |
| No deploy-rs service config | **High** | User + sudo rules suggest deploy-rs intent, but no flake input or activation agent is defined yet. |
| Hardcoded SSH public key | **Low** | Fine for personal infra; consider sops or agenix for rotation. |

---

## `hosts/omen/hardware-configuration.nix`

This file appears to be output from `nixos-generate-config` on an **existing traditional install**:

- `/` on ext4 (not tmpfs)
- `/boot`, `/persistent`, swap with fixed UUIDs
- Uses `lib.mkDefault` but function args are `{ }` — **`lib` is undefined**; will not evaluate.

**Do not import this alongside the disko module** unless you remove its `fileSystems`/`swapDevices` (keep only initrd kernel modules, CPU microcode, platform). As written it conflicts with the ephemeral disko layout.

---

## `hosts/omen/configuration.nix`

The `myHardware` option values themselves are coherent for a laptop with NVMe + HDD/SSD secondary disk. Specific device paths (`/dev/nvme0n1`, `/dev/sda`) must be confirmed on the Omen hardware — by-id paths are safer for disko.

---

## Recommended Next Steps (priority order)

1. Wire omen into `flake.nix` with `disko` input and corrected module paths.
2. Fix `deploy.nix` (`pkgs` in args) and disko ESP mount options.
3. Add tmpfiles rules for bind-mount **target** directories on tmpfs root.
4. Add `allowUnfree`; validate NVIDIA bus IDs on hardware.
5. Integrate sops-nix for Tailscale auth key (and optionally deploy secrets).
6. Either delete or slim `hardware-configuration.nix` to initrd/modules only.
7. Test with `nixos-rebuild build` locally, then disko dry-run / nixos-anywhere on the target machine.

---

## Feasibility Verdict

| Component | Feasible? | Confidence |
|-----------|-----------|------------|
| Ephemeral root + disko layout | Yes, with fixes | High |
| NVIDIA PRIME offload | Yes, with allowUnfree + bus ID check | High |
| Tailscale persistence | Yes, once bind mounts + auth key provisioning work | Medium |
| deploy-rs remote deploy | Not yet — needs flake wiring + deploy-rs + fixed deploy module | Low (design only) |
| End-to-end from current repo state | **No** | — |

The architecture is viable; the gap is integration and a handful of correctness bugs, not a fundamental design flaw.

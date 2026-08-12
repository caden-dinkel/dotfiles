# Project Review

## Overview

This flake manages two system tiers:

- **darwin** (`mac-m3`, aarch64-darwin) — nix-darwin + home-manager workstation
- **omen** (x86_64-linux) — headless NixOS server with impermanence, disko, and deploy-rs

The design philosophy is correct: ephemeral root via btrfs snapshot rollback, Tailscale-gated SSH, deploy-rs for remote pushes, and sops-nix for secrets (in progress). The module abstractions (`myHardware.disk`, `myHardware.nvidia`) are clean and will compose well when more hosts are added.

---

## What's Working Well

### `forEachHost` abstraction (`flake.nix`)
Clean pattern. Adding a new host requires only adding its name to `hostsByArch` and a `hosts/<name>/configuration.nix`. Both `nixosConfigurations` and `deploy.nodes` are derived automatically.

### Impermanence + rollback
The btrfs rollback in `modules/rollback.nix` is correct — it mounts subvolid=5 (the btrfs root), deletes the stale `/root` subvolume, and snapshots `/root_blank` in its place, all inside the initrd before the real root mounts. The persistence list in `modules/persist.nix` covers the right state: tailscale identity, SSH host keys, machine-id, and logs.

### Tailscale key lifecycle
The pattern of placing the auth key at `/etc/tailscale/authkey`, having the service consume it on first boot, and clearing it afterward is sound. Because `/etc` is ephemeral, the key is automatically gone after rollback, and `/var/lib/tailscale` (persisted) provides tailnet membership on subsequent boots.

### NVIDIA module
The `myHardware.nvidia` option is well structured. The `prime` sub-option is there for laptops with hybrid graphics, defaulting to off for omen's discrete-only setup.

### Deployment security
The deploy user has narrowly scoped passwordless sudo: only `switch-to-configuration` and `nix-env`. The admin user's full NOPASSWD sudo is intentional for emergency console access and is acceptable given the threat model of a home server.

---

## Issues and Gaps

### `anywhere-omen.sh` — broken, cannot run as-is

**Syntax error on line 15:** `end` is not valid bash. Should be `;;`.

**Argument parsing is broken (lines 9–11):** All three cases assign `"$1"` (the flag name itself) instead of `"$2"` (the value). Correct form:
```bash
-target_ip) TARGET_IP="$2"; shift ;;
-tailscale_auth_key) TAILSCALE_KEY="$2"; shift ;;
-sops_pub_key) SOPS_PUB_KEY="$2"; shift ;;
```

**Target IP is hardcoded (line 38):** `$TARGET_IP` is parsed but never used — the nixos-anywhere call has `root@192.168.1.232` literally. Should be `root@$TARGET_IP`.

**`$TAILSCALE_KEY` is never used:** The script fetches the key from Bitwarden instead, which is fine, but accepting `-tailscale_auth_key` as a parameter is misleading. Either remove the parameter and document the Bitwarden dependency, or use the parameter directly and skip Bitwarden.

**`$BW_SESSION` is an implicit dependency:** The script relies on this environment variable being set but never validates it. Should check and error out early.

### `hardware-configuration.nix` is a blank stub

`hosts/omen/hardware-configuration.nix` contains only `# Blank file for testing\n{}`. The NOTES file explains how to generate the real one via nixos-anywhere's `--generate-hardware-config` flag, but this requires the provisioning script to work first (see above).

### Networking in `base.nix` is misconfigured for omen

`base.nix` configures `networking.wireless.iwd.enable = true` and a `systemd.network` rule for `wlan0`. Omen is a desktop (NVIDIA GPU, NVMe + SATA drives) — it presumably connects via ethernet, not WiFi. The wlan0 configuration almost certainly doesn't match any real interface on omen.

Additionally, `/etc/NetworkManager/system-connections` is persisted in `persist.nix`, but NetworkManager is not enabled anywhere in the config. Either the persist entry should be removed, or ethernet should be configured via NetworkManager (and `networking.useNetworkd` disabled).

### SOPS is partially wired but no secrets exist yet

`.sops.yaml` is configured with an age key and a pattern for `secrets/[^/]+\.(yaml|json|env|ini)$`, but there is no `secrets/` directory and no actual secret files. Darwin's `sops.nix` just points to the key file location. The sops-nix input and darwin module are in place — the next step is to identify what actually needs to be a secret (Tailscale auth key being the obvious candidate) and create the secrets directory.

### `microvm` input is declared but unused

The flake imports `microvm` as an input and passes it through `outputs`, but there are no `microvm` outputs and the input is not passed as a `specialArg` to any system. It's ready to use but dead weight until the aarch64 linux-builder replacement work begins.

### darwin linux-builder only covers `aarch64-linux`

`nix.linux-builder.systems = [ "aarch64-linux" ]`. Building for omen (`x86_64-linux`) from the Mac will still hit remote builders or fail locally. This is noted in the TODO (microvm task) but worth flagging explicitly: deploying to omen from darwin currently requires either a remote x86_64 build cache or building on omen itself.

### Hostname uniqueness (acknowledged in TODO)

`mkNode` produces `${hostname}.rainbow-dorian.ts.net` as the deploy target, which is correct assuming one machine per profile name. The TODO correctly identifies that if two machines share the same profile name they'd collide on Tailscale. The fix is either per-machine hostname overrides or separating profile name from hostname.

---

## Structural Observations

**No NixOS home-manager.** Omen only has `admin` and `deploy` users — both system-only. If a regular interactive user is ever needed on omen, home-manager is not wired up for NixOS hosts (only darwin has it).

**`cdink.nix` is darwin-specific.** It sets `home = "/Users/cdink"` which is a macOS path. If a cdink user is ever needed on NixOS, a separate or conditional definition will be required.

**skhd keybinding hardcodes a macOS app path.** `"/Users/cdink/Applications/Home Manager Apps/WezTerm.app"` will break if the username changes or HM changes the app install location. Using `open -n -a WezTerm` (assuming wezterm is in PATH) would be more robust.

**deploy-rs `nix-env` path is fragile.** The deploy user's sudo rule allows `${pkgs.nix}/bin/nix-env` — this expands to a specific nix store path at build time. If nix is upgraded, the path changes and the sudo rule stops matching. A wildcard like `/nix/store/*-nix-*/bin/nix-env` would be more robust.

**Comment debt in pam.nix.** `# Don't have my watch setup yet.` — fine as a temporary note, should become real config or be removed when the watch situation is resolved.

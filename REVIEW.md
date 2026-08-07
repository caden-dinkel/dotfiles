# Flake Review

## Overview

The setup is clean and well-structured for a homelab. The core design decisions — BTRFS impermanence with rollback, deploy-rs over Tailscale, disko for declarative disk layout — are solid. The concerns below are ordered roughly by severity.

---

## Bugs

### 1. `remove-tailscale-authkey` targets the wrong path

In `modules/tailscale.nix`, the cleanup service zeroes out `/etc/nixos-secret/tailscale_key`, but the actual auth key is placed at `/etc/tailscale/authkey` (the value of `keyPath`). These paths don't match, so the cleanup service is a no-op.

```nix
# keyPath = "/etc/tailscale/authkey"
script = ''
  (: > /etc/nixos-secret/tailscale_key)  # wrong path, does nothing
'';
```

The auth key sits on disk permanently. As noted in NOTES, tailscale ignores the key once `/var/lib/tailscale` holds an identity, so there's no functional breakage — but the key remains on disk unzeroed. Fix by aligning the path, or use `rm` rather than truncation so the file is gone entirely:

```nix
script = ''
  rm -f ${keyPath}
'';
```

---

## Security

### 2. `admin` and `deploy` share the same SSH key

Both `users/admin.nix` and `users/deploy.nix` use `mac@cdink.dev` (`ssh-ed25519 AAAAC3...`). A single key compromise simultaneously grants both emergency shell access and deployment authority. These should be separate keys so each role has independent blast radius.

### 3. Auth key survives on disk

Follows from bug #1 above. Until the cleanup service is fixed, the Tailscale auth key (a tagged, reusable key retrieved from Bitwarden) lives at `/etc/tailscale/authkey` indefinitely. On the current setup this doesn't survive rollback (the key is on the ephemeral root, not in `/persist`), so risk resets on reboot. But it's on disk for the duration of an uptime.

### 4. `admin` has `NOPASSWD ALL` sudo

Intentional for an emergency user, but worth documenting. If the `mac@cdink.dev` key is compromised, an attacker has passwordless root on every host that imports `users/admin.nix`. Consider scoping it or at minimum adding a comment in the file explaining the deliberate tradeoff.

---

## Architecture & Design

### 5. No SOPS integration on NixOS hosts

The darwin host has sops-nix configured (`hosts/darwin/sops.nix`), but the omen host imports no sops module and has no secrets management. The `.sops.yaml` only contains the `admin_mac` age key — there's no host key for omen. Any secrets needed on omen (beyond the Tailscale auth key) have no mechanism. See the SOPS Provisioning section below for the full recommendation.

### 6. `microvm` input imported but unused

`flake.nix` declares `microvm` as an input, but nothing in the flake references it. Either use it or remove it to keep the lock file lean.

### 7. `aarch64-linux = []` in `hostsByArch`

This is a no-op entry that generates no outputs. If it's forward-looking, a comment would clarify intent. Otherwise remove it.

### 8. Darwin linux-builder only targets `aarch64-linux`

The `nix.linux-builder` in `hosts/darwin/configuration.nix` builds for `aarch64-linux`. The NixOS hosts are `x86_64-linux`. The Mac can't use that builder to cross-compile for omen. If you want to evaluate or test NixOS configs locally, you'd need either Rosetta emulation (slow) or a separate remote builder pointing at an x86_64 machine. This probably isn't a daily-driver concern but worth knowing.

### 9. Only `wlan0` is configured in `base.nix`

`modules/base.nix` configures a single `wlan0` interface with DHCPv4. If omen has ethernet (and a gaming-class machine likely does), it's not wired up. There's also no fallback — if wifi drops, the host is unreachable. Consider adding an ethernet match using `matchConfig.Type = "ether"` or a specific interface name so wired connectivity is available.

### 10. `nix.settings.trusted-users` inconsistency

Darwin uses `trusted-users = [ "@admin" ]` (the `admin` group), while omen uses explicit user strings `[ "root" "admin" ]`. Neither is wrong, but the inconsistency is worth noting if you add more hosts — use the group form consistently (`"@wheel"` or `"@admin"`) so you don't have to remember to update the list per-host.

### 11. `hardware-configuration.nix` is overwritten on every `nixos-anywhere` run

The `--generate-hardware-config nixos-generate-config ./hosts/omen/hardware-configuration.nix` flag regenerates and overwrites the committed file each time you run `anywhere-omen.sh`. For a single machine this is benign (the hardware doesn't change), but any manual tweaks to that file would be silently discarded on re-provision. Consider removing the flag after the initial install and committing the generated file.

---

## Minor / Style

- `watchIdAuth = true` is commented out in `hosts/darwin/pam.nix`. If it's waiting on hardware support, a comment explaining why would be helpful.
- `flake.nix` checks only cover deploy-rs deployment validation. Adding a `nix flake check` step that evaluates `nixosConfigurations` would catch evaluation errors before deployment.
- `programs.git` in `modules/home/git.nix` sets `package = pkgs.git` explicitly — this is the default and can be omitted.
- `core.sshCommand = "ssh"` is also the default and can be omitted.
- `services.journald.extraConfig = "Storage=persistent"` in `base.nix` and `/var/log` in `persist.nix` work together, but the explicit extraConfig is redundant when `/var/log` is bind-mounted from `/persist/var/log`. Either one would be sufficient.

---

## SOPS Age Key Exchange in Provisioning

### The Problem

SOPS requires each host to have an age private key at a known path so sops-nix can decrypt secrets during activation. For a new host this creates a bootstrapping problem:

1. You need the host's age public key to encrypt secrets for it.
2. The host doesn't have a key until it's provisioned.
3. Some secrets (credentials, API keys) may be needed on first boot.

### Recommended Approach: Pre-generate and inject via nixos-anywhere

`nixos-anywhere`'s `--extra-files` already injects the Tailscale auth key. The same mechanism works for the sops age key. Because `/persist` is a separate BTRFS subvolume that survives rollbacks, injecting the key there means it persists across reboots.

**Workflow:**

1. Pre-generate an age keypair locally during provisioning.
2. Inject the private key to `/persist/var/lib/sops-nix/keys.txt` via `--extra-files`.
3. Output the public key so you can add it to `.sops.yaml` and encrypt host-specific secrets.
4. Configure sops-nix on the host to use that path.

**Changes to `anywhere-omen.sh`:**

```bash
#!/usr/bin/env bash

set -euo pipefail

set -a
source .env
set +a

temp=$(mktemp -d)

cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

# Tailscale auth key
install -d -m755 "$temp/etc/tailscale"
bw get password TAIL_SCALE_AUTH_SERVER --session "$BW_SESSION" \
  | install -m600 /dev/stdin "$temp/etc/tailscale/authkey"

# SOPS age key for omen
sops_dir="$temp/persist/var/lib/sops-nix"
install -d -m700 "$sops_dir"
age-keygen -o "$sops_dir/keys.txt" 2>/dev/null
chmod 600 "$sops_dir/keys.txt"

# Print the public key so you can add it to .sops.yaml
pub_key=$(grep "^# public key:" "$sops_dir/keys.txt" | awk '{print $4}')
echo ""
echo "==> Add the following to .sops.yaml under omen's key group:"
echo "    - &omen ${pub_key}"
echo ""
echo "Then run: sops updatekeys secrets/<file>.yaml"
echo "Press enter when ready to proceed with provisioning..."
read -r

nixos-anywhere \
  --extra-files "$temp" \
  --flake '.#omen' \
  --target-host root@192.168.1.232 \
  --generate-hardware-config nixos-generate-config ./hosts/omen/hardware-configuration.nix
```

**Changes to `.sops.yaml`:**

```yaml
keys:
  - &admin_mac age152dq9nhuj0lhgelpzt8h9mwvntpm8nu3ds3dh3wczm5vyla25u8s2jjt65
  - &omen <generated-public-key>
creation_rules:
  - path_regex: secrets/[^/]+\.(yaml|json|env|ini)$
    key_groups:
      - age:
        - *admin_mac
  - path_regex: secrets/omen/[^/]+\.(yaml|json|env|ini)$
    key_groups:
      - age:
        - *admin_mac
        - *omen
```

**Changes to `hosts/omen/configuration.nix`:**

```nix
imports = [
  ...
  inputs.sops-nix.nixosModules.sops
  ./sops.nix
];
```

**New `hosts/omen/sops.nix`:**

```nix
{
  sops.age.keyFile = "/var/lib/sops-nix/keys.txt";
}
```

**Why not SSH host keys?**

`sops.age.sshKeyPaths` lets you derive the age key from the SSH ed25519 host key (already persisted at `/etc/ssh`). This is tempting because it avoids a separate key file, but the SSH host key is generated by openssh on first activation — you can't know its public key before provisioning. You'd have to provision first, SSH in to get the public key, update `.sops.yaml`, re-encrypt secrets, then redeploy. The pre-generate approach avoids that two-phase dance.

**Re-provision idempotency**

On re-provision, nixos-anywhere will overwrite the injected key with a freshly generated one, invalidating any encrypted secrets. To guard against this, the script could check for an existing persisted key (e.g., by SSHing to the host first) and skip key generation if one already exists. Alternatively, keep a local copy of the private key in a Bitwarden vault entry and retrieve it during provisioning instead of re-generating.

---

## Summary Checklist

| Item | Severity | Action |
|------|----------|--------|
| Cleanup service wrong path | Bug | Fix path to `${keyPath}` or use `rm` |
| `admin`/`deploy` share SSH key | Security | Generate separate keys |
| No SOPS on omen | Gap | Add sops-nix, inject key via provisioning |
| `microvm` input unused | Cleanup | Remove or use |
| Only `wlan0` configured | Reliability | Add ethernet interface match |
| `hardware-configuration.nix` overwritten | Risk | Remove `--generate-hardware-config` after initial install |
| `aarch64-linux = []` in hostsByArch | Cleanup | Remove or add comment |

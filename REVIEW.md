# Flake Review

Goal: impermanent NixOS server setup, deploying via deploy-rs over Tailscale, with BTRFS root rollback on every boot.

---

## Critical Issues (will block a working deploy)

### 1. SSH is never enabled

`base.nix` has no `services.openssh.enable = true`. Without it, the server will have no SSH daemon after the first nixos-anywhere installation and you won't be able to reach it for subsequent `deploy-rs` runs. Add this to `base.nix`:

```nix
services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "no";
  };
};
```

### 2. SSH host keys not persisted

Even after enabling OpenSSH, the host keys live under `/etc/ssh/ssh_host_*` which is on the ephemeral root — they will be regenerated every boot. Every client connecting after a reboot will get a host-key-changed warning, and automated tooling (deploy-rs, scripts) will fail. Add to `persist.nix`:

```nix
files = [
  "/etc/machine-id"
  "/etc/ssh/ssh_host_ed25519_key"
  "/etc/ssh/ssh_host_ed25519_key.pub"
  "/etc/ssh/ssh_host_rsa_key"
  "/etc/ssh/ssh_host_rsa_key.pub"
];
```

### 3. No networking configuration

`base.nix` doesn't set up any network interface. The system will boot with no working network (and therefore no Tailscale, no SSH). At minimum add:

```nix
networking.useDHCP = lib.mkDefault true;
```

Or use `systemd-networkd` if you prefer, but something must bring up the physical interface before Tailscale can connect.

### 4. Tailscale auth key is unresolved

`tailscale.nix` has `authKeyFile = null` with a comment acknowledging this is unfigured-out. Without an auth key on first boot, Tailscale will start but never join the tailnet — your `deploy.nodes` hostname resolution (`${hostname}.rainbow-dorian.ts.net`) will fail on every subsequent deploy.

The canonical flow for this setup is:
1. Generate a reusable (or one-time) tagged auth key in the Tailscale admin console.
2. Encrypt it with SOPS using the host's age key (derived from its SSH ed25519 host key via `ssh-to-age`).
3. Set `authKeyFile = config.sops.secrets.tailscale_authkey.path`.

The chicken-and-egg for first boot (host key doesn't exist yet to derive the age key) is solved by using nixos-anywhere's `--extra-files` flag to drop the auth key at the expected path before the first activation — nixos-anywhere supports this. Alternatively, use a one-time key and just accept that the first deploy is semi-manual.

---

## Significant Issues (functional gaps)

### 5. SOPS not configured for the NixOS host

`sops.nix` is only imported in the darwin configuration. The omen host has no SOPS setup, which means:
- No secrets can be decrypted on the server at runtime.
- The Tailscale auth key (item 4 above) can't be managed declaratively.
- `.sops.yaml` only has one age key (the mac), so there's no server host key to decrypt with anyway.

Once you have SSH host keys persisted (item 2), derive the host age key:
```bash
ssh-keyscan omen.rainbow-dorian.ts.net | ssh-to-age
```
Then add it to `.sops.yaml` under a new `&omen_host` anchor and re-encrypt your secrets. Add to `hosts/omen/configuration.nix` (or a new `hosts/omen/sops.nix`):

```nix
sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
```

Note the path is under `/persist` — since the real key is there, not `/etc/ssh` (which is ephemeral).

### 6. `rollback.nix` mounts by `/dev/root` — fragile

The rollback script does `mount -t btrfs -o subvolid=5 /dev/root /btrfs_tmp`. The symlink `/dev/root` isn't guaranteed to exist in all initrd environments, and it points to whatever the kernel decided is the root device — which could be wrong if disk enumeration is non-deterministic. Use a UUID or label instead:

```bash
mount -t btrfs -o subvolid=5 /dev/disk/by-label/nixos /btrfs_tmp
```

Add a `partitions.root.label` to `disko.nix` to ensure the label exists:

```nix
root = {
  priority = 3;
  size = "100%";
  content = {
    extraArgs = [ "-f" "-L" "nixos" ];   # add the label here
    type = "btrfs";
    ...
```

Also add `set -euo pipefail` as the first line of the script so any failure aborts cleanly rather than silently.

### 7. `impermanence` module `enable` option may not exist

`persist.nix` sets `environment.persistence."/persist".enable = true`. The NixOS impermanence module does have this option, but it was added relatively recently. If you're on an older pin this will fail. More importantly: the `enable` option defaults to `true`, so explicitly setting it is harmless but worth knowing — removing it slightly simplifies the config.

### 8. `nix.settings.trusted-users` includes `deploy`

In `hosts/omen/configuration.nix`, the `deploy` user is listed in `trusted-users`. Trusted users can pass arbitrary options to the Nix daemon (override `sandbox`, use `--impure`, substitute from arbitrary caches). The deploy user only needs to run a switch-to-configuration script and manipulate one symlink — it should not be a trusted Nix user. Remove `"deploy"` from that list.

---

## Moderate Issues (correctness and robustness)

### 9. Spurious `impermanence` follows in flake.nix

```nix
impermanence = {
  url = "github:nix-community/impermanence";
  inputs.nixpkgs.follows = "";       # impermanence has no nixpkgs input
  inputs.home-manager.follows = "";  # impermanence has no home-manager input
};
```

The impermanence flake has no external inputs. These `follows = ""` lines are dead and slightly confusing. Remove them.

### 10. `microvm` input is unused

`microvm` is declared as an input but never referenced in any module or output. Dead inputs slow down `nix flake update` and add noise to the lock file. Remove it unless you're about to use it.

### 11. Flake description is stale

`description = "Example nix-darwin system flake"` — update this to describe what the flake actually is.

### 12. `tailscale.nix` uses `inputs.nixpkgs.lib` instead of `lib`

```nix
serviceConfig = {
  Restart = inputs.nixpkgs.lib.mkForce "on-failure";
```

The module already receives `lib` as a parameter. Use `lib.mkForce` directly. This works as-is (since `inputs` is in scope via `specialArgs`) but it's coupling a module to the flake's input namespace, which will break if the module is ever used outside this flake.

### 13. `swap` partition has `resumeDevice = true`

For a server, hibernate/resume from swap is almost certainly not desired. `resumeDevice = true` causes the kernel to emit a `resume=` cmdline parameter and adds initrd complexity. Set it to `false`.

### 14. Missing `nix.settings.experimental-features` in `base.nix`

Darwin has `nix.settings.experimental-features = "nix-command flakes"` but the NixOS `base.nix` doesn't. Without it, running `nix` commands (as opposed to legacy `nix-*` commands) on the server requires `--extra-experimental-features`. Add this to `base.nix`:

```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

Note the NixOS option expects a list, not a space-separated string.

### 15. Same SSH key for `admin` and `deploy`

Both `users/admin.nix` and `users/deploy.nix` authorize the same key (`mac@cdink.dev`). These are separate roles with different privileges — they should use different key pairs. If you ever need to rotate or revoke access to the deploy slot (e.g., automate it with a CI key), you don't want to accidentally also affect your emergency admin access (or vice versa).

### 16. `admin` user has NOPASSWD ALL

The admin user is passwordless sudo for everything. This is intentional for an emergency account, but it's worth being deliberate: any attacker who gets the private key for that SSH key can do anything on the system without further authentication. The risk is bounded by the key security, which is acceptable — just keep the key offline or behind a hardware security key.

### 17. No firewall allowance for Tailscale

The NixOS default firewall is enabled by default. Without explicitly trusting the `tailscale0` interface, services running on Tailscale IPs may be blocked. Add to `tailscale.nix`:

```nix
networking.firewall = {
  trustedInterfaces = [ "tailscale0" ];
  allowedUDPPorts = [ config.services.tailscale.port ];
};
```

---

## Minor Issues (style and future-proofing)

### 18. `nvidia.nix` uses `with lib`

`with lib;` at the top of `nvidia.nix` imports the entire `lib` namespace. This works but obscures where names come from and can shadow locals. Prefer explicit references: `lib.mkIf`, `lib.mkOption`, `lib.mkEnableOption`, etc.

### 19. NVIDIA PRIME offload mode for a server

The omen host uses `nvidia.prime.offload.enable = true` which is the laptop power-saving PRIME mode (Intel drives the display, NVIDIA renders on demand). If omen is a desktop or is being used headlessly as a server, consider whether you need PRIME at all. If you intend to use the NVIDIA GPU for compute (ML inference, Plex transcoding, etc.), sync mode or no PRIME (just run everything on NVIDIA) is likely more appropriate.

Also: `services.xserver.videoDrivers = [ "modesetting" "nvidia" ]` — having both listed can cause conflicts. For PRIME offload, just `[ "nvidia" ]` is typically sufficient; the modesetting driver for the integrated GPU is handled automatically.

### 20. Secondary disk has no persistence or backup consideration

The `/storage` btrfs filesystem on the secondary disk is mounted but never referenced in `persist.nix` or anywhere else. This is fine — it's persistent by definition (it's not on the ephemeral root). Just worth being deliberate: if you store data there, it won't be rolled back, which is what you want, but there's no mention of it in the persistence configuration so it could be confused with managed state.

### 21. `nix-darwin` input pinned to `master`

```nix
nix-darwin = {
  url = "github:nix-darwin/nix-darwin/master";
```

`master` is a moving target. The `flake.lock` pins the exact commit so you're reproducible — but `nix flake update` will pull whatever master is at that moment. If a breaking nix-darwin API change lands, your mac config breaks. Consider pinning to a specific release tag (`release-25.05` etc.) or staying on `master` consciously since you use nixpkgs-unstable anyway.

### 22. `hardware-configuration.nix` is a stub

This is noted in NOTES as intentional (nixos-anywhere will generate it). Just ensure the nixos-anywhere command in your deploy flow includes `--generate-hardware-config nixos-generate-config ./hosts/omen/hardware-configuration.nix` before building, otherwise the blank stub will evaluate but produce a non-bootable system (missing `boot.initrd.availableKernelModules`, etc.).

---

## Summary of Recommended Changes Priority

| Priority | File | Change |
|----------|------|--------|
| Critical | `modules/base.nix` | Add `services.openssh.enable = true` |
| Critical | `modules/base.nix` | Add `networking.useDHCP = lib.mkDefault true` |
| Critical | `modules/persist.nix` | Persist SSH host keys |
| Critical | `modules/tailscale.nix` | Resolve auth key delivery via SOPS + nixos-anywhere `--extra-files` |
| Critical | `.sops.yaml` | Add host age key derived from SSH host key |
| High | `modules/rollback.nix` | Mount btrfs by label/UUID, add `set -euo pipefail` |
| High | `hosts/omen/configuration.nix` | Remove `deploy` from `trusted-users` |
| High | `modules/tailscale.nix` | Use `lib.mkForce` not `inputs.nixpkgs.lib.mkForce`, add firewall rules |
| Medium | `flake.nix` | Remove spurious impermanence follows, remove microvm input, fix description |
| Medium | `modules/base.nix` | Add `nix.settings.experimental-features` |
| Medium | `modules/disko.nix` | Set `resumeDevice = false` for swap, add btrfs label |
| Medium | `users/admin.nix` + `users/deploy.nix` | Use separate SSH keys per role |
| Low | `modules/nvidia.nix` | Remove `with lib`, reconsider PRIME mode for server use |

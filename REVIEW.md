# Flake Review

Architecture goal: impermanent NixOS server(s), easily provisioned to new hardware, managed remotely via deploy-rs over Tailscale, provisioned initially via nixos-anywhere. Darwin host managed alongside for convenience.

---

## Bugs

### `anywhere-omen.sh` — `authkey` created as a directory, not a file

```bash
install -d -m755 "$temp/etc/tailscale/authkey"  # BUG: -d creates a directory
bw get password TAIL_SCALE_AUTH_SERVER --session "$BW_SESSION" > "$temp/etc/tailscale/authkey"
```

`install -d` creates the full path as a directory tree — so `authkey` ends up as a directory, not a file. The redirect on the next line then fails ("Is a directory") and, since the script has `set -euo pipefail`, the whole provisioning run aborts before `nixos-anywhere` is ever called.

Fix:
```bash
install -d -m755 "$temp/etc/tailscale"
bw get password TAIL_SCALE_AUTH_SERVER --session "$BW_SESSION" \
  | install -m600 /dev/stdin "$temp/etc/tailscale/authkey"
```

Using `install -m600 /dev/stdin` sets permissions atomically and avoids the intermediate world-readable window you'd get from `> file; chmod 600 file`.

---

### `modules/base.nix` — `self` referenced but not in scope

```nix
{ config, lib, ... }:
{
  ...
  system.configurationRevision = self.rev or self.dirtyRev or null;
}
```

`self` is available as a `specialArg` and will be passed to every module, but Nix only binds arguments that are explicitly destructured. The `...` pattern silently drops them without making them usable by name. This will produce `undefined variable 'self'` at evaluation time.

Fix — add `self` to the function signature:
```nix
{ self, config, lib, ... }:
```

---

### `modules/rollback.nix` — `/dev/root` is not guaranteed to exist

```bash
mount -t btrfs -o subvolid=5 /dev/root /btrfs_tmp
```

`/dev/root` is a symlink created by some initrd generators, but its presence is not guaranteed across all kernel versions or initrd configurations. On systems where it is absent the rollback service silently fails and the root subvolume is never reset, defeating the entire impermanence setup without any visible error.

A more robust approach is to read the root device from `/proc/mounts` or `/proc/cmdline`, or to explicitly pass the device via a NixOS option. Many impermanence write-ups use:

```bash
rootDevice=$(findmnt -n -o SOURCE --target / | sed 's/\[.*\]//')
mount -t btrfs -o subvolid=5 "$rootDevice" /btrfs_tmp
```

Or — simpler and more reliable for disko-managed layouts — hard-code the resolved device path from the `myHardware.disk.mainDevice` option by threading `config` into the rollback module.

---

## Security Concerns

### `.env` contains a live Bitwarden session token

The `.env` file (`.gitignore`d, confirmed not committed) holds `BW_SESSION`. Bitwarden session tokens do expire on idle (default 15 minutes), but the file sits plaintext in the dotfiles directory. Any process running as your user can read it. This is low risk in practice for a personal machine, but worth being aware of. Consider sourcing the session fresh each run (`bw unlock`) rather than caching it in a file.

### `admin` user has unconditional `NOPASSWD: ALL`

```nix
security.sudo.extraRules = [{
  users = [ "admin" ];
  commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
}];
```

If the SSH key for `admin` is ever compromised, the attacker has full root without any additional credential. This is the intended design (emergency breakglass user), so it is a deliberate trade-off rather than a mistake — but it means the security of the entire server rests entirely on the secrecy of that one ed25519 key. Consider:
- Using a separate key for `admin` vs. `deploy` rather than the same public key for both.
- Adding `requireTTY` for admin sudo so it cannot be driven non-interactively.

### Both `admin` and `deploy` share the same SSH public key

`users/admin.nix` and `users/deploy.nix` currently list the same key (`mac@cdink.dev`). This collapses the two roles into one: an attacker who gains the key can deploy arbitrary NixOS configs. `deploy` is correctly restricted to only the sudo commands deploy-rs needs; consider giving it a separate key so that compromising the deploy workflow doesn't also grant shell access as a wheel user.

### SOPS is configured on Darwin but not wired up for NixOS

`.sops.yaml` exists and `sops-nix` is an input, but no `sops` secrets are declared anywhere in the NixOS host configs. The tailscale authkey is currently delivered via nixos-anywhere's `--extra-files`, which is one-time provisioning only. For ongoing secret rotation (e.g. re-keying tailscale, adding service credentials) there is no mechanism in place.

---

## Observations & Recommendations

### `microvm` input is unused

`microvm` is declared as a flake input and follows nixpkgs, but is never referenced in any output. It adds evaluation time and a line in `flake.lock`. Remove it until you need it.

### Secondary disk has no mount options

The primary disk partitions use `compress=zstd` and `noatime`. The secondary disk does not:

```nix
partitions.data = {
  size = "100%";
  content = {
    type = "filesystem";
    format = "btrfs";
    mountpoint = "/storage";
    # no mountOptions
  };
};
```

Add `mountOptions = [ "compress=zstd" "noatime" ]` here for consistency and to get the same space/performance benefits on `/storage`.

### Secondary disk device defaults to `/dev/sda`

Kernel device names are not stable across reboots or hardware changes — a USB drive plugging in before boot can shift `sda` to `sdb`. For disko layouts, prefer `/dev/disk/by-id/` paths. The option description could note this and the `example` could show the `by-id` form.

### `services.xserver.videoDrivers = [ "nvidia" ]` on a headless server

`nvidia.nix` sets `services.xserver.videoDrivers = [ "nvidia" ]`. This pulls in X11 server infrastructure even though this is a headless server. For GPU compute (CUDA, ML inference, transcoding), you want the nvidia driver loaded but not X11. Consider using:

```nix
hardware.nvidia.nvidiaPersistenced.enable = true; # keeps GPU initialized
```

and dropping the `xserver.videoDrivers` line, or setting `services.xserver.enable = false` explicitly so future modules don't accidentally start X.

### `persist.nix` missing systemd journal persistence

`/var/log` is persisted, but journald writes to `/var/log/journal` only if that directory exists and `Storage=persistent` is set in journald config. Without that, logs go to the volatile `/run/log/journal` and are lost on every rollback. Add:

```nix
services.journald.extraConfig = "Storage=persistent";
```

(or set it via `systemd.journald.extraConfig`) so journal logs survive reboots and are actually in the persisted `/var/log`.

### `/etc/NetworkManager/system-connections` persisted but NetworkManager may not be in use

`base.nix` uses `networking.useDHCP = lib.mkDefault true`, which typically works without NetworkManager. If you end up using `systemd-networkd` instead (common in headless server setups), the NetworkManager persist entry is dead weight. Worth deciding early: NetworkManager or systemd-networkd, then either wire up the appropriate service or drop the persist entry.

### `nix.linux-builder` on Darwin cannot cross-compile `x86_64-linux`

```nix
nix.linux-builder = {
  systems = [ "aarch64-linux" ];
  ...
};
```

The linux-builder VM runs on `aarch64-linux` (your M3). It can build native `aarch64-linux` packages but cannot build `x86_64-linux` ones. Builds for the `omen` host will still be done locally or on the remote machine itself. This is probably fine — just worth knowing so you don't wonder why distributed builds aren't helping with omen deploys.

### Tailscale authkey removal service ordering gap

`remove-tailscale-authkey` runs `after = [ "tailscale.service" ]`. But "tailscale service started" does not mean "tailscale has completed registration." If the machine has no network on first boot, tailscaled starts, fails to register, and the authkey is deleted before registration completes — leaving the machine unregistered with no way to re-register (the key is gone and `/etc/tailscale/authkey` is not in the persist list).

Options:
1. Add `/etc/tailscale/authkey` to the persist list, and rely on tailscale's own behavior of ignoring the authkey when `/var/lib/tailscale` already has a node key.
2. Check for successful registration before removing: run `tailscale status` in the remove service's `ExecStartPre` and only proceed if it exits 0.
3. Accept the risk and document the recovery procedure (re-provision with nixos-anywhere).

The NOTES file already documents that tailscale checks `/var/lib/tailscale` for existing identity and ignores the authkey if present, so option 1 is the simplest.

### `forEachHost` is a good abstraction — extend it consistently

The `forEachHost` helper cleanly scales to multiple hosts. One thing to watch: `mkNode` hard-codes the Tailscale domain suffix `rainbow-dorian.ts.net`. When you add hosts, if they live in a different tailnet (e.g. a future staging tailnet), you'd need to branch. Consider making the domain a flake-level option or at minimum a named `let` binding so it's easy to find and change.

### `flake.nix` outputs destructuring leaves some inputs implicit

```nix
outputs = { self, nix-darwin, nixpkgs, ... }@inputs:
```

`nix-darwin` is destructured explicitly but only used as `nix-darwin.lib.darwinSystem`, which could equally be `inputs.nix-darwin.lib.darwinSystem`. Being consistent — either use `inputs.X` everywhere or destructure explicitly — makes it easier to grep for input usage when trimming the flake.

### Hardware config workflow needs documentation

`NOTES` mentions that hardware config is generated via `--generate-hardware-config` during `nixos-anywhere` and saved to `./hosts/omen/hardware-configuration.nix`. This file is tracked in git but generated externally. It should either be in `.gitignore` with a note to regenerate it, or the generation step should be documented clearly. As it stands, a new contributor cloning the repo would find `hardware-configuration.nix` missing (it's not committed until after first provisioning) and the flake evaluation would fail.

---

## What's Working Well

- The BTRFS subvolume layout for impermanence (`/root`, `/nix`, `/persist`, `/root_blank`) is correct and matches established community patterns.
- `neededForBoot = true` on `/persist` is correctly set.
- Rollback timing (`before = [ "sysroot.mount" ]`, `after = [ "initrd-root-device.target" ]`) is correct.
- `deploy.nix` sudo rules are correctly scoped — deploy user cannot run arbitrary commands.
- `PasswordAuthentication = false` and `PermitRootLogin = "no"` are set in base SSH config.
- `myHardware` option namespace is clean and avoids collisions.
- `forEachHost` will scale naturally as hosts are added.
- `sops-nix` is included as an input for future secrets management even if not yet wired up.
- The `authkey` removal service is a good hygiene step regardless of whether the key is persisted.

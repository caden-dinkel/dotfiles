# Provisioning

This covers two scenarios: **initial provisioning** (bare metal → running NixOS) and **adding a new host** to the flake.

---

## Initial Provisioning (nixos-anywhere)

### What gets passed out-of-band

Two files must be present on the target **before** the first activation. They are passed via `nixos-anywhere --extra-files` and are never committed to the repository:

| Destination on target          | What it is                                 |
|--------------------------------|--------------------------------------------|
| `/etc/tailscale/authkey`       | One-time tagged Tailscale auth key         |
| `/var/lib/sops-nix/keys.txt`   | age private key for SOPS decryption        |

The Tailscale auth key must be a **tagged, single-use** key from the Tailscale admin panel. After the host registers, the `remove-tailscale-authkey` systemd service zeros the file. Do not put this key in SOPS — it's intentionally ephemeral.

The age key should be generated fresh per host. Print or note the public key before provisioning so you can add it to `.sops.yaml`.

### Step-by-step

1. **Generate an age key pair** for the new host:
   ```sh
   age-keygen -o /tmp/<hostname>-age.key
   # note the public key printed to stdout
   ```

2. **Add the age public key** to `.sops.yaml` under `creation_rules` for this host, then re-encrypt any secrets the host needs:
   ```sh
   sops updatekeys secrets/<file>.yaml
   ```

3. **Obtain a Tailscale auth key** (single-use, tagged) from the Tailscale admin panel.

4. **Stage the extra files** in a temp directory:
   ```sh
   mkdir -p /tmp/extra-files/etc/tailscale
   mkdir -p /tmp/extra-files/var/lib/sops-nix
   echo "<tailscale-auth-key>" > /tmp/extra-files/etc/tailscale/authkey
   cp /tmp/<hostname>-age.key /tmp/extra-files/var/lib/sops-nix/keys.txt
   chmod 600 /tmp/extra-files/etc/tailscale/authkey
   chmod 600 /tmp/extra-files/var/lib/sops-nix/keys.txt
   ```

5. **Run nixos-anywhere**:
   ```sh
   nix run github:nix-community/nixos-anywhere -- \
     --flake .#<hostname> \
     --extra-files /tmp/extra-files \
     --generate-hardware-config nixos-generate-config ./hosts/<hostname>/hardware-configuration.nix \
     root@<install-target-ip>
   ```

   The `--generate-hardware-config` flag writes the generated `hardware-configuration.nix` back to your local checkout so you can commit it.

6. **Commit the generated hardware config**:
   ```sh
   git add hosts/<hostname>/hardware-configuration.nix
   git commit -m "hosts/<hostname>: add generated hardware config"
   ```

7. **Clean up** staging files and the age private key from `/tmp`.

On first boot:
- Tailscale registers using the auth key, then `remove-tailscale-authkey` zeros `/etc/tailscale/authkey`
- SOPS decrypts secrets using the age key at `/var/lib/sops-nix/keys.txt`
- If the disk is ephemeral, the initrd rolls back root to the blank btrfs snapshot before mounting

---

## Adding a New Host to the Flake

1. **Create the host directory**:
   ```
   hosts/<hostname>/
     default.nix       # sets networking.hostName, imports profile + role
     metadata.nix      # imports platform metadata (and deployable.nix if applicable)
   ```

   Example `default.nix` for a new NixOS server:
   ```nix
   { self, ... }:
   {
       networking.hostName = "<hostname>";
       imports = [
           "${self}/profiles/desktop"
           "${self}/roles/server.nix"
           ./hardware-configuration.nix
       ];
   }
   ```

   Example `metadata.nix`:
   ```nix
   {
       imports = [
           ./metadata/nixos-x86_64.nix
           ./metadata/deployable.nix   # omit if not deploying via deploy-rs
       ];
   }
   ```

2. **Choose or create a profile** under `profiles/`. A profile sets `nixpkgs.hostPlatform` and `myHardware` options (disk layout, GPU). If an existing profile matches the hardware, reuse it and override device paths with `lib.mkForce` in `hosts/<hostname>/default.nix` if needed.

3. **Choose a role**: `roles/personal.nix` (pulls in desktop + home-manager) or `roles/server.nix` (pulls in system users + tailscale).

4. **Update `.sops.yaml`** with the new host's age public key if the host needs to decrypt secrets.

5. The flake picks up the new host automatically — `builtins.readDir ./hosts` enumerates it at eval time.

---

## Subsequent Deployments

For deployable hosts (currently `charlie`):
```sh
nix run github:serokell/deploy-rs -- .#<hostname>
```

This SSHes to `<hostname>.rainbow-dorian.ts.net:2222` as the `deploy` user and runs `sudo switch-to-configuration switch`.

For local rebuilds:
```sh
# NixOS
nixos-rebuild switch --flake .#<hostname>

# darwin
darwin-rebuild switch --flake .#<hostname>
```

---

## Re-provisioning an Existing Host

Because root is ephemeral, re-provisioning wipes only the root subvolume (which gets rolled back on every boot anyway). `/persist` contains durable state and will be **overwritten** by nixos-anywhere unless you exclude it.

If you want to preserve `/persist` (e.g., existing Tailscale identity, host SSH keys):
- Do not use `--extra-files` for the age key or Tailscale key — the existing ones in `/persist` are still valid
- Confirm the host is still enrolled in Tailscale before skipping the auth key step
- If re-generating from scratch, treat it as an initial provisioning

---

## Known Gaps (WIP)

- `modules/apps/provision.nix` is a stub intended to become a flake app wrapping the nixos-anywhere workflow above. Until it is implemented, use the manual steps in this document.
- A `devShells` output with `deploy-rs`, `nixos-anywhere`, `sops`, and `age` pinned to the flake's nixpkgs is planned but not yet present. In the meantime, use `nix run` or install these tools via nix-env.

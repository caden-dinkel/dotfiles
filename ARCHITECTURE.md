# Architecture

## Overview

The flake follows a four-layer composition model: **hosts → profiles → roles → modules**. Each layer narrows scope — hosts are concrete machines, profiles describe hardware, roles describe purpose, and modules implement the actual configuration.

A single `builtins.readDir` in `flake.nix` enumerates everything under `hosts/`, so adding a new machine is just creating a directory with `default.nix` and `metadata.nix`. No edits to the flake core are required.

---

## Layer Model

```
flake.nix
└── hosts/<name>/default.nix        # sets hostname, imports profile + role
    ├── profiles/<profile>/         # hardware: disk layout, GPU, platform
    │   ├── configuration.nix       # sets nixpkgs.hostPlatform + myHardware options
    │   └── disko-hardware.nix      # imports disko + hardware modules
    ├── roles/<role>.nix            # purpose: which users and modules to activate
    │   ├── personal.nix            # → cdink user, desktop modules
    │   └── server.nix              # → system users, tailscale module
    └── modules/                    # platform-dispatched module tree
        ├── common/                 # all platforms: packages, nix settings, revision
        ├── darwin/                 # macOS: packages, system defaults, DNS
        ├── linux/                  # NixOS: boot, networkd, openssh on 2222
        ├── desktop/                # UI: fonts, skhd (darwin), Hyprland + greetd (linux)
        ├── hardware/
        │   ├── nvidia.nix          # myHardware.nvidia options
        │   └── disko/              # myHardware.disk options + ephemeral root setup
        ├── software/
        │   ├── tailscale.nix       # server tailscale: auth key, firewall, key clearing
        │   └── sops/               # sops-nix integration (age key path)
        └── home/                   # home-manager integration per user
```

### Platform Dispatch

`modules/default.nix` and `modules/desktop/default.nix` use `lib.optionals pkgs.stdenv.isDarwin` / `isLinux` to import the right platform subtree. This means modules can be unconditionally imported by any role without worrying about whether the host is macOS or NixOS.

---

## Host Metadata

Each host's `metadata.nix` imports one or more files from `hosts/metadata/`:

```
hosts/metadata/
  darwin-aarch64.nix   # { system = "aarch64-darwin"; type = "darwin"; }
  nixos-x86_64.nix     # { system = "x86_64-linux";   type = "nixos"; }
  nixos-aarch64.nix    # { system = "aarch64-linux";   type = "nixos"; }  (reserved, Pi)
  deployable.nix       # { deployable = true; }
```

These are **plain Nix attrsets** (no function wrapper), consumed directly by `flake.nix` via `import ./hosts/${name}/metadata.nix` to determine system architecture, configuration builder (`nixosSystem` vs `darwinSystem`), and whether to include the host in `deploy.nodes`. Host `default.nix` files are NixOS/darwin modules and import these separately.

---

## Hardware Modules

### Disk (`myHardware.disk`)

The disko module exposes a structured option set:

```nix
myHardware.disk = {
  main = {
    enable    = true;
    device    = "/dev/nvme0n1";   # lib.mkDefault in profile, overrideable per-host
    ephemeral = true;             # enables btrfs rollback-to-blank on boot
    swap.enable = true;
    swap.size   = "32G";
  };
  secondary = {
    enable = true;
    device = "/dev/sda";
  };
};
```

When `ephemeral = true`, the initrd runs a rollback script before mounting root: it deletes the `root` btrfs subvolume and re-creates it from the `root-blank` snapshot taken at install time. `/persist` is a separate subvolume that survives reboots and contains durable state (e.g. `/var/lib/tailscale`, SOPS age key, SSH host keys).

### NVIDIA (`myHardware.nvidia`)

```nix
myHardware.nvidia = {
  enable  = true;
  package = config.boot.kernelPackages.nvidiaPackages.stable;  # or legacy_580
  open    = true;   # open-source kernel module (Turing+ GPUs)
};
```

The module blacklists `nouveau`, enables `modesetting`, and turns on `nvidiaPersistenced`.

---

## Networking

### Tailscale

All hosts participate in the `rainbow-dorian.ts.net` tailnet. The Tailscale module (`modules/software/tailscale.nix`) is imported by `roles/server.nix` and handles:

- Auth key from `/etc/tailscale/authkey` (written during provisioning, never committed)
- `--hostname` set to `config.networking.hostName` on first `tailscale up`
- Firewall: `tailscale0` is trusted, UDP port for Tailscale is allowed
- A oneshot systemd service (`remove-tailscale-authkey`) zeros the key file after the daemon registers, so the auth token does not persist on disk

On subsequent boots, Tailscale reads its existing identity from `/var/lib/tailscale` (persisted across ephemeral reboots via disko's `/persist` mount).

### SSH

SSH runs on **port 2222** on all Linux hosts (`modules/linux/services.nix`). Password authentication and root login are disabled. The intended access model is:

- **Automated deployment** (`deploy-rs`, future CI): standard SSH on port 2222, keyed to the `deploy` user
- **Interactive/emergency access**: SSH through Tailscale to the `admin` user

The non-standard port avoids conflicts with Tailscale SSH if it is ever enabled alongside standard SSH.

---

## Users

### UID Registry

`users/registry.nix` is the single source of truth for stable UIDs across all hosts. `users/default.nix` wraps each user module with a `mkUser` helper that injects the registry UID.

```
admin      UID 901   Emergency server access (wheel, NOPASSWD ALL)
deploy     UID 902   deploy-rs automation (minimal sudo: switch-to-configuration + nix-env)
monitoring UID 903   Allocated, not yet implemented
```

### `cdink`

The personal user. On Linux: `isNormalUser`, `wheel` + `networkmanager` + `bluetooth` groups, zsh shell. On Darwin: `system.primaryUser`. Importing `users/cdink.nix` automatically pulls in the home-manager profile (`modules/home/`).

### `deploy`

System user. Authenticates via SSH public key. Has passwordless sudo for exactly two commands: `switch-to-configuration switch` (any store path) and `nix-env` (current system). This is the minimum required for `deploy-rs` to activate a new NixOS configuration.

### `admin`

Normal user with a locked password and wheel group membership. `NOPASSWD ALL` sudo for emergency recovery when automated deployment is broken. Intended access is SSH-key-only.

---

## Secrets (SOPS + age)

`.sops.yaml` defines encryption rules for `secrets/**`. Currently one key group: the `admin_mac` age key held on the darwin workstation.

The age private key for each NixOS host lives at `/var/lib/sops-nix/keys.txt` (inside `/persist`). It is delivered out-of-band during provisioning (via `nixos-anywhere --extra-files`) and is never committed to the repository.

The intended secret model:
- **Tailscale auth key**: one-time use, passed as `--extra-files` during provisioning only, never in SOPS
- **Tailscale OAuth key**: long-lived, goes into SOPS
- **Other secrets**: SOPS-encrypted YAML under `secrets/`, decrypted at NixOS activation

For a new host to decrypt SOPS secrets, its age public key must be added to `.sops.yaml` and secrets must be re-encrypted with `sops updatekeys`.

---

## Deployment (deploy-rs)

`deploy.nodes` is generated automatically in `flake.nix` for all hosts where `metadata.deployable == true`. Currently that is only `charlie`.

Each node deploys to `<hostname>.rainbow-dorian.ts.net` on port 2222 as the `deploy` user. `deploy-rs` uses `sudo` to call `switch-to-configuration switch` on the target.

`nix flake check` runs `deploy-rs.lib.*.deployChecks` to validate deployment configs before pushing.

---

## Darwin (alpha)

`alpha` is a MacBook Pro (aarch64). It uses `nix-darwin` instead of NixOS. The darwin profile is thin — it sets `nixpkgs.hostPlatform` and relies on the platform-dispatched module tree for the rest. Notable darwin-specific config:

- `modules/darwin/system.nix`: Finder preferences, Dock autohide, DNS, `system.stateVersion`
- `modules/darwin/packages.nix`: `vfkit` for future VM use
- Desktop: `skhd` for hotkeys (keybindings partially stubbed)
- `system.primaryUser = "cdink"` set via `cdink.nix`

---

## Home Manager

Home Manager is integrated at the system level (not standalone). `modules/home/default.nix` imports the appropriate Home Manager module from `inputs.home-manager` and sets `useGlobalPkgs = true; useUserPackages = true` to avoid a second nixpkgs evaluation.

User-level home configuration lives under `modules/home/`:
```
modules/home/
  home.nix         # home-manager wrapper: dispatches common + darwin/linux
  common/          # shared dotfiles / programs
  darwin/          # macOS-specific home config
  linux/           # Linux-specific home config (awww wallpaper daemon, etc.)
```

The `userName` arg is threaded through `_module.args` from `users/cdink.nix` so home modules do not hardcode a username.

---

## Future Hosts

`hosts/metadata/nixos-aarch64.nix` exists but is unused — it is reserved for a future Raspberry Pi. The aarch64-linux slot in `deploy.nodes` generation handles it automatically once a host directory and `deployable.nix` are added.

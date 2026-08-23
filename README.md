# dotfiles

NixOS and nix-darwin system configurations for a small personal fleet, managed as a single Nix flake.

## Hosts

| Host    | OS             | Profile      | Role     | Deployable |
|---------|----------------|--------------|----------|------------|
| alpha   | aarch64-darwin | darwin       | personal | no         |
| bravo   | x86_64-linux   | desktop      | personal | no         |
| charlie | x86_64-linux   | omen-laptop  | server   | yes        |

Linux hosts use ephemeral root (btrfs rollback on boot). `charlie` is the only host currently reachable via `deploy-rs`; `alpha` and `bravo` rebuild locally.

## Prerequisites

- Nix with flakes enabled (`nix.settings.experimental-features = "nix-command flakes"`)
- Tailscale access to `rainbow-dorian.ts.net` for remote operations
- `sops` + `age` for secret management
- `deploy-rs` for remote deployments (`nix run github:serokell/deploy-rs`)
- `nixos-anywhere` for initial host provisioning

## Common Commands

**Rebuild darwin (alpha) locally:**
```sh
darwin-rebuild switch --flake .#alpha
```

**Rebuild a NixOS host locally:**
```sh
nixos-rebuild switch --flake .#bravo
```

**Deploy a remote NixOS host via deploy-rs:**
```sh
nix run github:serokell/deploy-rs -- .#charlie
```

**Validate the flake (includes deploy-rs checks):**
```sh
nix flake check
```

**Re-encrypt secrets after adding a new host:**
```sh
sops updatekeys secrets/<file>
```

## Repository Structure

```
hosts/          # Per-host entry points and metadata
  <name>/
    default.nix       # NixOS/darwin module entry point (sets hostname, imports profile + role)
    metadata.nix      # Imports platform metadata (type, system, deployable)
    hardware-configuration.nix  # nixos-generate-config output (NixOS only)
  metadata/     # Shared platform metadata attrsets consumed by flake.nix
profiles/       # Hardware-level configs (disk layout, GPU driver, platform)
  darwin/       # macOS profile
  desktop/      # x86_64 desktop with NVidia (open driver) + ephemeral NVMe
  omen-laptop/  # x86_64 laptop with NVidia (legacy_580) + ephemeral NVMe + secondary disk
roles/          # Role-level configs pulled in by hosts
  personal.nix  # Pulls in desktop modules and the cdink user (with home-manager)
  server.nix    # Pulls in system users and Tailscale module
modules/        # Shared NixOS/nix-darwin modules
users/          # User declarations and global UID registry
secrets/        # SOPS-encrypted secrets (age-encrypted YAML/env files)
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for a detailed breakdown of the module system and design decisions.

## Adding a New Host

See [PROVISIONING.md](PROVISIONING.md) for the full workflow including nixos-anywhere, SOPS key setup, and Tailscale enrollment.

## Roadmap

Active TODOs and planned work are tracked in [TODO/TODO.md](TODO/TODO.md).
Completed items are in [TODO/TOODONE.md](TODO/TOODONE.md).

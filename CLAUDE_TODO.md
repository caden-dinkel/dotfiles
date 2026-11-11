# TODO: VM-testable host refactor

Goal restated: any host in `hosts/` can be built/booted as a VM and smoke-tested
before it's deployed for real, routed through `hosts/mkhost.nix` instead of
each host's `default.nix` being wired directly into `flake.nix`.

This supersedes the old root-level `TODO` file's "2 top level definitions
(vm/hdh) per host" item — `mkhost.nix` is that mechanism now. The `TODO` file
can be deleted once this document's Phase 1-3 land.

Reviewed: `flake.nix`, `hosts/*`, `profiles/*`, `modules/*`, `microvms/*`,
`tests/*`, `scripts/provision-new-machine.nix`. Snapshot as of 2026-11-08,
branch `feature/host-builder`.

---

## 0. Blocking bugs (fix independent of the refactor)

These will break any `mkhost.nix`-based config too, so fix before building on
top of them:

- [ ] `hosts/alpha/default.nix:17` and `hosts/bravo/default.nix:20` import
      `../../modules/home.nix`, but the file actually lives at
      `modules/home/home.nix`. Path is currently dangling.
- [ ] `hosts/alpha/default.nix:19` and `hosts/charlie/default.nix:15` import
      `../../modules/state-version.nix`, which does not exist anywhere in the
      repo (`system.stateVersion` is already set generically in
      `modules/common.nix:20`, so these imports are likely just stale).

## 1. Finish the hardware/software split that's already half-done

`profiles/desktop.nix`, `profiles/omen.nix`, `profiles/macbook.nix` exist and
contain hardware config, but the hosts weren't pruned to match:

- [ ] `hosts/bravo/default.nix` still inlines the *exact* nvidia/graphics
      block, `boot.initrd.availableKernelModules`, `boot.blacklistedKernelModules`,
      `boot.kernelParams`, and `services.xserver.videoDrivers` that now also
      live in `profiles/desktop.nix`. Delete the duplicate from the host file.
- [ ] `hosts/charlie/default.nix` has the same duplication against
      `profiles/omen.nix` (nvidia block + `boot.blacklistedKernelModules`),
      plus it owns the *entire* disko layout (both disks). Decide how much of
      the disko layout is "hardware" (device paths, disk count — belongs in
      the profile) vs "software" (partition scheme, filesystem choices,
      subvolumes — arguably stays with the host). Right now it's 100% in the
      host; `desktop.nix`/`omen.nix` only carry `.device` overrides.
- [ ] `hosts/alpha/default.nix` is in reasonable shape already — only the
      darwin-specific `services.yabai` and `nix.linux-builder` blocks are
      arguably "hardware" (they're alpha-the-machine-specific, not
      alpha-the-role-specific) and could move to `profiles/macbook.nix`
      alongside the existing `sudo_local`/TouchID block. Lower priority than
      bravo/charlie since nothing is duplicated yet.
- [ ] Once split, create the flat per-host **software-only** files that
      `hosts/mkhost.nix` already expects but don't exist yet:
      `hosts/alpha.nix`, `hosts/bravo.nix`, `hosts/charlie.nix`. These replace
      `hosts/alpha/default.nix` etc. (minus the hardware bits moved above).
      `hosts/bravo/hardware-configuration.nix` (the nixos-generate-config
      output) is a separate concern — see Phase 2.

## 2. Wire `hosts/mkhost.nix` into `flake.nix`

`hosts/mkhost.nix` exists and takes `{ lib, host, isVm }`, but **nothing in
`flake.nix` calls it yet** — `nixosConfigurations`/`darwinConfigurations`
still import `./hosts/alpha`, `./hosts/bravo`, `./hosts/charlie` directly.

- [ ] Replace each `nixosConfigurations.<x>`/`darwinConfigurations.<x>` host
      module list entry (`./hosts/bravo`, etc.) with `./hosts/mkhost.nix`,
      passing `host = "bravo";` (etc.) via `specialArgs`.
- [ ] `specialArgs` are currently inconsistent per host — alpha/bravo get
      `{ self inputs git name home-manager sops-nix }`, charlie only gets
      `{ self inputs disko }` (no `git`, `name`, `home-manager`, `sops-nix` —
      meaning `modules/home.nix`/`modules/sops.nix` imports in charlie's host
      file must not actually be using those names, or charlie is already
      partially broken). Standardize one `specialArgs` set used for every
      host, since `mkhost.nix` is now the common entry point and every
      software file needs the same args available.
- [ ] `hosts/mkhost.nix` needs `isVm` threaded into `specialArgs` for every
      `nixosConfigurations.<host>` call — default `false` for the real
      deploy target, and add a parallel VM-flavored output (see Phase 4) that
      sets it `true`.
- [ ] `disko.nixosModules.disko` is currently added manually per-host in
      `flake.nix` (bravo, charlie) since disko doesn't apply to darwin. Once
      `mkhost.nix` is the shared entry, decide whether `mkhost.nix` itself
      should conditionally import the disko module based on platform, or
      whether `flake.nix` keeps doing it per-output. Leaning toward keeping
      it in `flake.nix` next to the `nixosSystem`/`darwinSystem` call, since
      `mkhost.nix` has no clean way to know "is this a darwin build" before
      `nixpkgs.hostPlatform` is evaluated.
- [ ] `hosts/bravo/hardware-configuration.nix` is machine-specific
      (nixos-generate-config output, tied to bravo's real NVMe/kernel
      modules) — once bravo's host file moves to flat `hosts/bravo.nix`,
      this generated file needs a new home. Likely `profiles/desktop.nix`
      should `import`/inline it, or it moves to something like
      `hosts/bravo/hardware-configuration.nix` kept as-is with
      `profiles/desktop.nix` referencing it directly. Needs a decision — see
      marked section below.
- [ ] `scripts/provision-new-machine.nix:77` hardcodes
      `$repo_root/hosts/$machine_name/hardware-configuration.nix` as the
      `--generate-hardware-config` output target for `nixos-anywhere`. If
      hosts stop being directories (`hosts/bravo/` → `hosts/bravo.nix`), this
      path breaks. Update once the directory layout is finalized.

## 3. Make disko VM-size-aware (the sizing problem you flagged)

Right now `isVm` is only honored in **one** place —
`hosts/charlie/default.nix:106` (`size = if isVm then "1G" else "32G";` for
swap) — and `isVm` is never actually set to `true` anywhere in the flake, so
this branch is dead code today. `hosts/bravo/default.nix:95` has the same
32G swap partition with no `isVm` check at all. If a VM build reuses the real
disko layout unmodified, the disk image has to be ≥ ESP(1G) + swap(32G) just
to fit the partition table, which is wasteful/slow for a throwaway test VM
and will outright fail if the VM disk image is sized smaller than that.

- [ ] Decide where the size-shrinking logic lives (see **DECISION** callout
      below — recommend moving it out of each host file and into
      `profiles/vm.nix` via `lib.mkVMOverride`/`lib.mkForce`, rather than
      threading `isVm ? ... : ...` ternaries through every host's disko
      block, since that pattern already got missed once (bravo) and will get
      missed again on every new host).
- [ ] Whatever approach is chosen, apply it consistently to **both** bravo
      and charlie's swap partitions, and audit `root` partitions too — both
      currently use `size = "100%"`, which is fine as long as the VM's
      backing disk image itself is sized appropriately for a test (not the
      32G+ a real deploy needs).
- [ ] Decide how large the VM's backing disk image actually is (disko image
      builds need an explicit size, e.g. via `disko.devices.disk.<x>.imageSize`
      for disko's image-building mode) and make sure it's comfortably bigger
      than ESP + shrunk-swap + whatever root actually needs for a smoke test.
- [ ] `profiles/vm.nix` currently only sets `.device` (`/dev/vda`, `/dev/vdb`)
      — it's the natural place to also carry the VM-specific size overrides
      once the above is decided, keeping all "this disk is virtual hardware"
      concerns in one file instead of spread across every host.

## 4. Actually build + boot a host as a VM

There's currently no flake output that builds any host as a bootable VM.
`microvms/*.nix` and `tests/tailscale-connect.nix` are a separate, existing
pattern (hand-written microvm/NixOS-test declarations, not "take host X and
VM-ify it"), and don't currently share code with `hosts/mkhost.nix`.

- [ ] Add a flake output per NixOS host that builds it as a VM with
      `isVm = true` (e.g. `nixosConfigurations.bravo-vm`, or a `vmConfigurations`
      attrset, or packages like `packages.x86_64-linux.bravo-vm`) — naming is
      an open call, see decision section.
- [ ] Decide the actual VM mechanism — `nixos-rebuild build-vm`/
      `virtualisation.vmVariant`, `nixos-anywhere --vm-test`, or wrapping the
      host in a `microvm.nix` declaration like the existing `microvms/*`
      files do. These test *different* things (see marked decision below) —
      pick the one that matches "test prior to deployment," which probably
      means more than one tier.
- [ ] `darwinConfigurations.alpha` has no real VM story — nix-darwin doesn't
      support `virtualisation.vmVariant`-style local VM builds the way
      nixpkgs does, and `isVm` in `hosts/mkhost.nix` would just swap
      `profiles/macbook.nix` for `profiles/vm.nix`, which makes little sense
      for a Mac. Explicitly decide alpha is either out of scope for this
      effort, or scope down what "VM-tested" means for it (e.g. just eval/
      build-check, no boot test).
- [ ] Hook whatever VM target gets chosen into a `checks.<system>.<host>-boots`
      or similar flake check, so "test prior to deployment" can eventually be
      `nix flake check` rather than a manual step.

## 5. Secrets in a VM

`sops.age.generateKey = false` + `sops.age.keyFile` pointed at
`~/.config/sops/age/keys.txt` (`modules/sops.nix:8`) means every host expects
a real, pre-existing age key to decrypt `secrets/tailscale.yaml` and
`secrets/deploy-rs-key`. A freshly-booted test VM won't have one.
`tests/tailscale-connect.nix` already has a comment flagging this exact gap
("Need to come up with a method to get runtime secrets into this test vm.")
— it's unresolved there too.

- [ ] Decide how a test VM gets a usable (test-only) age key and/or
      test-only secrets file, so hosts that `import ../../modules/sops.nix`
      don't just fail to activate under `isVm = true`. Options: a
      `isVm`-gated stub secrets file, injecting a throwaway key via the VM's
      shared files/`--extra-files` (same mechanism `provision-new-machine.nix`
      already uses for the real tailscale authkey), or gating
      `modules/sops.nix`'s imports behind `isVm` entirely for a reduced
      "software boots" smoke test that doesn't touch secrets at all.

## 6. Consistency pass once the above lands

- [ ] `modules/deploy-user.nix`'s `deploy` user and sudo rules are server-
      oriented (`myUsers.deploy`); confirm whether VM smoke tests should
      enable it at all or whether it should stay opt-out for `isVm = true`.
- [ ] Re-check every host's `specialArgs` usage (`name`, `git`, `home-manager`,
      `sops-nix`) is actually consumed by the flattened `hosts/<x>.nix` files
      — charlie's current file doesn't reference several of them, worth
      confirming nothing is silently relying on a missing arg.
- [ ] Delete the root `TODO` file once its contents (hardware/software split,
      vm/hdh-style host factory) are superseded by this document.

---

## ⚠️ DECISIONS NEEDED (flagging explicitly, not deciding for you)

1. **What does "test as a VM" actually mean here?** Three different things
   got conflated in the existing repo and in "test prior to deployment":
   - *Fast smoke test*: does the config evaluate/build and boot at all
     (`nixos-rebuild build-vm` style — shares the host's `/nix/store`, no
     disko/bootloader exercised).
   - *Disk/bootloader test*: does disko partition correctly and does the
     bootloader come up on a real synthetic disk image (closer to what
     `nixos-anywhere --vm-test` or a disko image build gives you).
   - *Integration test*: does the host actually come up on the tailnet etc.,
     closer to the existing `tests/tailscale-connect.nix` /
     `microvms/headscale-server.nix` three-VM pattern described in `NOTES`'s
     sibling file `TODO`.
   My recommendation: treat these as separate tiers rather than picking one.
   Tier 1 (build-vm) is cheap and should run on every host via `mkhost.nix`
   + `isVm`. Tier 2/3 reuse the existing microvm-test machinery and don't
   need to go through `mkhost.nix` at all.

2. **Where does `hosts/bravo/hardware-configuration.nix` live after the
   flattening?** It's real, machine-generated, and tied to bravo's actual
   NVMe/kernel-module reality — it's not really "profile" material (it's not
   reusable across machines the way `profiles/desktop.nix` is) but it also
   doesn't fit a flat `hosts/bravo.nix` file cleanly. Suggest keeping a
   `hosts/bravo/` directory *just* for this generated file, imported from
   `hosts/bravo.nix`, rather than trying to force it into `profiles/`.

3. **Naming/shape of the VM flake outputs** (Phase 4) — a parallel
   `nixosConfigurations.<host>-vm` attrset is the least surprising option
   given `nixosConfigurations.test-microvm` already exists as a precedent,
   but a dedicated `vmConfigurations.<host>` attrset would keep
   `nixosConfigurations` limited to "things that get deployed for real."

---

## >> ALTERNATE DIRECTION WORTH CONSIDERING <<

Instead of threading `isVm` as a boolean through every layer (host file →
disko sizes → `mkhost.nix` → specialArgs), consider making **the VM-ness
live entirely in `profiles/vm.nix` as an override module**, and never let
host files branch on `isVm` at all:

- `hosts/mkhost.nix` already picks `profiles/vm.nix` *instead of* the real
  hardware profile when `isVm = true` — that's the right shape, keep it.
- But rather than also handing `isVm` down to host files (as
  `hosts/charlie/default.nix` does today for swap size), have
  `profiles/vm.nix` itself carry `lib.mkForce`/`lib.mkVMOverride` overrides
  for anything that needs to shrink for a VM (swap size, any `size = "100%"`
  disk that's otherwise fine, disabling `myUsers.deploy`, disabling real
  tailscale auth in favor of a stub, etc.).
- This means host software files (`hosts/bravo.nix`, etc.) stay completely
  unaware that a VM variant exists — they just declare the real machine, and
  `profiles/vm.nix` is the single place that knows how to make *any* host
  cheap-and-bootable. It also fixes the "bravo forgot the isVm check, charlie
  didn't" inconsistency structurally instead of by code review.
- The tradeoff: disko partition *sizes* living in the hardware profile
  (`profiles/vm.nix`) rather than next to the partition *definitions*
  (currently 100% in the host file) means the full disko layout for a given
  host is now split across two files to read it end-to-end. Given the
  project's already splitting hardware/software this way elsewhere, that's
  probably consistent rather than a new cost — but worth being deliberate
  about.

This also sidesteps needing `isVm` as a `specialArg` at all in most places —
only `hosts/mkhost.nix` itself needs to know it, to choose which hardware
profile to import.

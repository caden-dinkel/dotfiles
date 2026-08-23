# Completed TODOs

[X] - `users/default.nix` is missing `in` between the `let` block and the body attrset. Parse error.

[X] - `modules/desktop/default.nix` references `lib` but does not declare it in function args. Fix: `{ pkgs, lib, ... }:`.

[X] - `modules/desktop/common/fonts.nix` references `pkgs` with no function args at all. Needs `{ pkgs, ... }:` added.

[X] - `modules/desktop/linux/system.nix` references `pkgs` with no function args. Needs `{ pkgs, ... }:`. Also ends with `};` (trailing semicolon at file level — syntax error).

[X] - `modules/desktop/linux/services.nix` is missing a semicolon after the greetd `command` value. Also ends with `};` (same trailing semicolon issue).

[X] - `hosts/bravo/default.nix` imports `${self}/metadata/linux-x86_64.nix` which does not exist. The file is `metadata/nixos-x86_64.nix`.

[X] - `inputs` is not passed in `specialArgs` (only `self` is). Four modules fail because of this: `modules/hardware/disko/default.nix`, `modules/hardware/disko/ephemeral/default.nix`, `modules/home/default.nix`, `modules/software/sops/default.nix`. Fix: add `inputs = self.inputs;` to `specialArgs` in both `nixosSystem` and `darwinSystem` calls in `flake.nix`.

[X] - `flake.nix` `getMeta` function does `import ./hosts/${name}/metadata.nix` but those files are module functions (`{ self, ... }:`), not plain attrsets. Accessing `.type` or `.deployable` on a function throws an error. Either make host `metadata.nix` files plain attrsets (no function wrapper), or restructure so `getMeta` reads from a separate flat file per host.

[X] - `modules/hardware/disko/disko.nix` imports `inputs.impermanence.nixosModule.impermanence` (singular) — wrong path. Should be `inputs.impermanence.nixosModules.impermanence` (plural). Also, both `disko.nix` and `ephemeral/default.nix` import impermanence independently — one of them should be removed.

[X] - `modules/software/tailscale.nix` (the complete tailscale module with auth key handling, firewall rules, and clear-after-boot service) is never imported anywhere. Wire it into `roles/server.nix` or a suitable module and remove the bare `services.tailscale.enable = true` from `modules/common/services.nix`.

[X] - `modules/home/linux/services.nix` declares `services.awww` which is not a real home-manager service. This is almost certainly a typo for `swww` (the Wayland wallpaper daemon). Confirm the correct home-manager module name and fix.

NOTE: Devs changed name from swww to awww.

[X] - Add a `monitoring` user module. `users/registry.nix` allocates UID 903 for `monitoring` but no user is defined or imported in `users/default.nix`.

[X] - Add `deploy-rs` checks output to `flake.nix` so `nix flake check` validates deployment configs:
  ```nix
  checks = builtins.mapAttrs (_: lib: lib.deployChecks self.deploy) deploy-rs.lib;
  ```
[X] - `profiles/omen-laptop/configuration.nix` uses wrong option names for both the nvidia and disko modules. The module API uses `myHardware.disk.main.device`, `myHardware.disk.main.swap.size`, `myHardware.disk.secondary.enable`, `myHardware.disk.secondary.device` — not `mainDevice`, `swapSize`, `enableSecondary`, `secondaryDevice`. The nvidia module also does not have a `prime` option; that reference should be removed.

[X] - `modules/apps/provision.nix` references `nixpkgs` and `nixos-anywhere` as if they're flake-level variables, but it's a module file — those are out of scope. Also, `nixos-anywhere` is not a flake input. Either move the provision app logic into `flake.nix` outputs directly, or restructure how the file is imported. Add `nixos-anywhere` as a flake input when implementing.

[X] - Need to adjust openSSH and tailscale. Should use normal ssh through port 2222, limiting traffic to the tailscale0 interface. This will avoid tailscale identity checks (manual step) for node provisioning. General access ssh will rely on tailscale, requiring manual ID.

[X] - Configure Microvm to produce an aarch64 microvm to be used as darwin's linux-builder. Check feasibility/gains of using rosetta internally for cross-compile.
Was added to upstream nix-darwin before I made it this far lol.

[X] - Ensure tailscale domains are <hostname>.tsdomain as a standard. If so, need to adjust method used to produce the system results. At the moment, any two systems deployed with the same profile, share the same hostname.
    Can be fixed by adjusting flake structure:
        systems/ (was hosts/) --- sets networking.hostName per host, also includes hardware-configuration.nix from system install.
        profiles/
        modules/
        users/
        .
        .
        .
NOTE: This has been fixed by the structure, but if possible, I'd like to add a method to produce many hosts programmatically, without requiring explicit configuration per host.

[X] - Figure out networking (There's a few alternatives I believe). Will have ethernet up to 3 hosts.

[X] - Set Global UIDs for users.

[X] - Finish module structure refactor. Now segmented by hardware profile, role, and host. user/software modules pulled by role. hardware modules pulled by profiles, host applies a role to profile and gives it a name. Darwin/linux is inherit to the module format and default imports. In the future, aarch64 vs x86 can be added on with the same scheme if needed.

[X] - Consider tying home-manager in with the users that are only on personal machines. This should be better instead of passing homeUser into personal.nix

[X] - Set up monitoring user (Or delete if not needed)

[X] - Adjust disko.nix file to allow for ephemeral or not systems.

[X] - flake.nix is outdated: still references non-existent hosts/darwin/configuration.nix and hostname "omen".
      Needs to be updated to use the new host entry points (hosts/alpha/alpha.nix, hosts/bravo/bravo.nix,
      hosts/charlie/charlie.nix) and the correct hostnames (alpha, bravo, charlie).

[X] - hosts/alpha/configuration.nix is the old monolithic darwin config and is no longer wired up correctly.
      Its content needs to be distributed into profiles/darwin/, modules/darwin/, modules/desktop/darwin/,
      and roles/personal.nix. The new hosts/alpha/alpha.nix entry point is ready but unused by the flake.

[X] - modules/linux/ is an empty stub. Needs Linux-specific NixOS modules (system.nix, packages.nix)
      as the counterpart to modules/darwin/.

[X] - modules/desktop/linux/ is an empty stub. Needs Linux desktop modules (window manager, display server config, etc.) as the counterpart to modules/desktop/darwin/.

[X] - Setup primaryUser on darwin.

[X] - modules/desktop/darwin/services/skhd.nix has a hardcoded /Users/cdink/ path. Should derive the WezTerm path from the configured userName so it works for any user.

[X] - Make the deploy user's `nix-env` sudo rule more robust. The current rule pins to `${pkgs.nix}/bin/nix-env` which is a specific store path. Consider using a glob pattern or `/run/current-system/sw/bin/nix-env` so it doesn't break silently on nix upgrades.

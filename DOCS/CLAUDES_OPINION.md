# Claude's Opinion

## On the Bootstrapping Problem

The core tension documented in `BOOTSTRAPPING_SYSTEM` is real: `flake.nix` needs
`system` and `type` before it can call `nixosSystem`/`darwinSystem`, but that
information lives inside the NixOS module tree that _is_ the system. The
`metadata.nix` pattern is the right instinct — the question is just the right shape.

---

### The Root of the Current Issue

The `hosts/${name}/metadata.nix` files are currently _NixOS module functions_
(`{ self, ... }: { imports = [...]; }`). `getMeta` does `import` on them, which
returns the lambda — then `.type` and `.system` are accessed on a function, which
Nix rejects with "cannot select from a function." The metadata files in
`hosts/metadata/*.nix` are plain attrsets, which is correct. The per-host wrapper
introduces the breakage.

---

### My Preference: Option 1, Repaired

Keep the dynamic `readDir` enumeration — it's genuinely good. The fix is to
enforce a strict split between two roles that the current code conflates:

- `hosts/${name}/meta.nix` — plain attrset, never a module, only read by `flake.nix`
- `hosts/${name}/default.nix` — NixOS/darwin module, never imports `meta.nix`

```nix
# hosts/charlie/meta.nix  (plain attrset — not a module)
{
  system     = "x86_64-linux";
  type       = "nixos";
  deployable = true;
}
```

`getMeta` then trivially works: `import ./hosts/${name}/meta.nix` returns the
attrset directly. No module function, no import chain, no shared metadata files
needed. Each host owns its own metadata in one flat file.

**Tradeoff:** you lose the shared `hosts/metadata/*.nix` files that avoid
copy-pasting `system`/`type` values. But since there are only a handful of valid
combinations, the duplication is minimal and the explicitness is worth it.

---

### Option 3: A Top-Level `hosts/registry.nix`

Not documented in `BOOTSTRAPPING_SYSTEM` yet. A single file that enumerates all
hosts and their build-time metadata:

```nix
# hosts/registry.nix
{
  alpha   = { system = "aarch64-darwin"; type = "darwin"; deployable = false; };
  bravo   = { system = "x86_64-linux";   type = "nixos";  deployable = false; };
  charlie = { system = "x86_64-linux";   type = "nixos";  deployable = true;  };
}
```

`flake.nix` replaces `builtins.readDir` + `getMeta` with:

```nix
let
  registry = import ./hosts/registry.nix;
  hostNames = builtins.attrNames registry;
  getMeta   = name: registry.${name};
in ...
```

**Advantages:**
- Partial/in-progress host directories don't break evaluation (no readDir scan)
- The full host list is visible in one place without filesystem traversal
- No dual-role confusion — this file is purely for flake.nix

**Disadvantages:**
- Adding a host now requires editing two things: create the directory AND update
  `registry.nix`. The current approach only requires the directory.
- If someone adds a host directory but forgets `registry.nix`, the host just
  silently doesn't build rather than erroring loudly.

I'd lean toward this approach once the host count grows past ~5, since the
readability payoff becomes obvious. For now, the repaired per-host `meta.nix` is
simpler.

---

### Option 4: `flake-parts`

Worth knowing about. `flake-parts` is a library that restructures flake outputs
into composable modules. The host enumeration and system builder logic would move
into dedicated modules rather than living inline in `flake.nix`.

```nix
# with flake-parts
{ inputs, ... }: {
  imports = [ inputs.flake-parts.flakeModules.easyOverlay ];
  systems = [ "x86_64-linux" "aarch64-darwin" ];
  perSystem = { pkgs, ... }: { ... };
}
```

The `nixos-flake` or `haumea` libraries sit on top of `flake-parts` and handle
NixOS/darwin enumeration with conventions similar to what you have now.

**I would not recommend this right now.** The added abstraction layer makes
debugging harder, and the current architecture is close enough to solid that it
doesn't need the framework. Come back to this if the flake grows to 10+ hosts or
multiple collaborators.

---

## Other Things Worth Addressing

### Metadata Being Used as Modules (REVIEW.md #13)

Beyond the `getMeta` breakage, the `hosts/metadata/*.nix` files are imported by
host `default.nix` files as NixOS modules. `system` and `type` are not valid NixOS
options, so these imports are noise — they either produce warnings or get silently
ignored. The module tree has no use for `system` or `type`; those belong only in
`flake.nix`. Remove these imports from `default.nix` files entirely.

### The `checks` Output Is Incomplete

`flake.nix` has:
```nix
checks = builtins.mapAttrs (_: lib: lib.deployChecks self.deploy) deploy-rs.lib;
```
This only runs deploy-rs validation. `nix flake check` could also be wired to
evaluate all `nixosConfigurations` and `darwinConfigurations` to catch evaluation
errors before deploy. That would have caught most of the bugs in `REVIEW.md` much
earlier.

### `devShells` Is Missing

There's no pinned dev environment. Anyone working on this repo has to have
`deploy-rs`, `nixos-anywhere`, `sops`, and `age` on their PATH from somewhere
else. A `devShells.default` that includes these tools keeps the tooling in sync
with the nixpkgs pin.


---

## What's Solid and Worth Keeping

The four-layer model (`hosts → profiles → roles → modules`) is clean and scales
well. The disko module design is genuinely good. The ephemeral-root pattern with
`/persist` is correct. Platform dispatch via `stdenv.isDarwin` is the right way to
handle cross-platform modules. The UID registry is smart. Keep all of this.

The dynamic host enumeration is the right instinct even if the current
implementation is broken. Repair it (Option 1 above) rather than replace it.

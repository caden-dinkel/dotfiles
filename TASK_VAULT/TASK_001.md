Convert current default.nix style into more idiomatic nix patterns.

NOTE: All of the {}: 

Current approach:

```nix
# modules/default.nix
{ pkgs, lib, ... }:
{
    imports = [
        ./common
    ] ++ lib.optionals pkgs.stdenv.isDarwin [
        ./darwin
    ] ++ lib.optionals pkgs.stdenv.isLinux [
        ./linux
    ];
}
```
```nix
# modules/darwin/default.nix
{
    imports = [
        ./system.nix
        ./packages.nix
    ];
}
```
```nix
# modules/darwin/packages.nix
{ pkgs, ... }:
{
    environment.systemPackages = [
        pkgs.vfkit
    ];
}
```

Issues:
The evaulation of pkgs is reliant on config. Conditional imports on config result in infinite recursion. 
Based on best practices, the conditional application should be pushed into the module definition (use `mkEnableOption` and `mkIf` to control) and the modules should be imported unconditionally. 

Fixed:

```nix
# modules/default.nix
{
    imports = [
        ./common
        ./darwin
        ./linux
    ];
}
```
```nix
# modules/darwin/default.nix
{
    imports = [
        ./system.nix
        ./packages.nix
    ];
}
```
```nix
# modules/darwin/packages.nix
{ lib, pkgs, ... }:
{
    config = lib.mkIf pkgs.stdenv.isDarwin {
        environment.systemPackages = [
            pkgs.vfkit
        ];
        # This is currently the entire file for packages.nix, just testing.
    };
}
```
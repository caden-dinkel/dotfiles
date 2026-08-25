Remove home-manager import from user.

Instead, the user and userDescription should be defined in roles/personal.nix, and passed to the home and user imports.

Use the following pattern, instead of module_args pattern.

```nix
#roles/personal.nix
{ pkgs, ... }:
let
  userName = "myname";
  userDescription = "My Name";
in
{
  imports = [
    # Call the user file passing an attribute set of arguments
    (import ./users/personal_user.nix { inherit userName userDescription pkgs; })
  ];
}
```
{ pkgs, ... }: {
  projectRootFile = "flake.nix";
  programs = {
    # Enable nixpkgsfmt or alejandra for Nix files
    nixfmt.enable = true;
  };
}

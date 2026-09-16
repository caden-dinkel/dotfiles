{ pkgs, ... }: {
  projectRootFile = "flake.nix";
  programs = {
    # Enable nixpkgsfmt or alejandra for Nix files
    nixfmt.enable = true;
    rustfmt.enable = true;
    prettier.enable = true; # for JS/TS/JSON/Markdown
  };
}

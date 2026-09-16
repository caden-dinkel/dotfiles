{pkgs, ...}: {
  projectRootFile = "flake.nix";
  programs = {
    # Enable nixpkgsfmt or alejandra for Nix files
    alejandra.enable = true;
    rustfmt.enable = true;
    prettier.enable = true; # for JS/TS/JSON/Markdown
  };
}

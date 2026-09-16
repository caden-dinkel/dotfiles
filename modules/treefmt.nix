{ pkgs, ... }:
{
    projectRootFile = "flake.nix";
    programs = {
        # Enable nixpkgsfmt or alejandra for Nix files
        nixpkgs-fmt.enable = true;
        
        # Add other formatters easily, e.g.:
        # prettier.enable = true; # for JS/TS/JSON/Markdown
        # rustfmt.enable = true;  # for Rust
    };
}
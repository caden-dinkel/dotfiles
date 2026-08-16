{
  services.skhd = {
    enable = true;
    package = pkgs.skhd;

    skhdConfig = ''
      cmd - return : open -na "/Users/cdink/Applications/Home Manager Apps/WezTerm.app"
    '';
  };
}

{
  services.skhd = {
    enable = true;
    package = pkgs.skhd;

    # Open terminal app. Need to be generic of user.
    # This is dependent on the home-manager so...
    # Should probably move it, but my structure is really nice.
    /*
    skhdConfig = ''
      cmd - return : open -na 
    '';
    */
  };
}
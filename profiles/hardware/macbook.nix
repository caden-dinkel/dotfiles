{
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    reattach = true;
  };
  nixpkgs.hostPlatform = "aarch64-darwin";
}

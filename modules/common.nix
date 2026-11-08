{
  self,
  pkgs,
  ...
}:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;

  system.configurationRevision = self.rev or self.dirtyRev or null;

  environment.systemPackages = [
    pkgs.git
  ];

  system.stateVersion = if pkgs.stdenv.hostPlatform.isDarwin then 6 else "26.05";
}

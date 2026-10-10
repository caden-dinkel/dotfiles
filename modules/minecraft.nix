{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.prismLauncher.override {
      jdks = [
        pkgs.termurin-bin-21
      ];
    })
  ];
}

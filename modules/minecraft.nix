{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.prismlauncher.override {
      jdks = [
        pkgs.temurin-bin-21
      ];
    })
  ];
}

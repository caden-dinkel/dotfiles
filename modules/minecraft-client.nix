{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.prismlauncher.override {
      jdks = [
        pkgs.temurin-bin-21
        pkgs.temurin-bin-25
      ];
    })
  ];
}

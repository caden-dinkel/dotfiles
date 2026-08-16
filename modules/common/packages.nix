{ pkgs, ... }:
{
    environment.systemPackages = [
        pkgs.age
        pkgs.git
    ];
}
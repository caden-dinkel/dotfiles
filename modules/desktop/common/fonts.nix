{ pkgs, ... }:
{
    # Maybe switch fonts. Have to try a few.
    fonts.packages = [
        pkgs.nerd-fonts.hack
        pkgs.nerd-fonts.jetbrains-mono
        pkgs.noto-fonts
        pkgs.noto-fonts-emoji
    ];
}
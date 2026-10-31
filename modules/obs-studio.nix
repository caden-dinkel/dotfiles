{ pkgs, config, ... }: {
  programs.obs-studio = {
    enable = true;
    package =
      if config.hardware.nvidia.enable then
        (pkgs.obs-studio.override {
          cudaSupport = true;
        })
      else
        pkgs.obs-studio;
    plugins = [
      pkgs.obs-studio-plugins.obs-pipewire-audio-capture
    ];
  };
}

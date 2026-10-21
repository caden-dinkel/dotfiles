{ pkgs, ... }: {
  services.thermald = {
    enable = true;
  };
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "schedutil";
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
      CPU_BOOST_ON_AC = 1;
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
    };
  };
  services.openssh = {
    enable = true;
  };
  networking.firewall.allowedTCPPorts = [ 22 ];
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };
  boot.kernelParams = [ "consoleblank=60" ];

  environment.systemPackages = with pkgs; [
    lm_sensors # Provides the 'sensors' command to check core temps
    powertop # Analyzes power drain
    htop # Quick process monitoring
  ];
}

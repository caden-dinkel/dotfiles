{ config, lib, pkgs, ... }:

with lib;

let 
    cfg = config.myHardware.nvidia;
in
{
    options.myHardware.nvidia = {
        enable = mkEnableOption "NVIDIA graphics support.";

        package = mkOption {
            type = types.package;
            default = config.boot.kernelPackages.nvidiaPackages.stable;
            description = "The NVIDIA driver package to use.";
            # Look into finding link
        };

        prime = {
            enable = mkEnableOption "NVIDIA PRIME hybrid graphics offloading.";

            intelBusId = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "PCI:0:2:0";
                description = "Bus ID of the Intel Integrated Graphics.";
            };

            nvidiaBusId = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "PCI:1:0:0";
                description = "Bus ID of the NVIDIA dedicated GPU.";
            };
        };
    };

    config = mkIf cfg.enable {
        hardware.graphics.enable = true;

        services.xserver.videoDrivers = [ "modesetting" "nvidia" ];

        boot.blacklistedKernelModules = [ "nouveau" ];

        hardware.nvidia = {
            package = cfg.package;
            modesetting.enable = true;
            open = false;

            prime = mkIf cfg.prime.enable {
                offload = {
                    enable = true;
                    enableOffloadCmd = true;
                };
                inherit (cfg.prime) intelBusId nvidiaBusId;
            };
        };
    };
}
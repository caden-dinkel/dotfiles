{ config, lib, pkgs, ... }:

let 
    cfg = config.myHardware.nvidia;
in
{
    options.myHardware.nvidia = {
        enable = lib.mkEnableOption "NVIDIA graphics support.";

        package = lib.mkOption {
            type = lib.types.package;
            default = config.boot.kernelPackages.nvidiaPackages.stable;
            description = "The NVIDIA driver package to use.";
            # Look into finding link
        };

        prime = {
            enable = lib.mkEnableOption "NVIDIA PRIME hybrid graphics offloading.";

            intelBusId = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                example = "PCI:0:2:0";
                description = "Bus ID of the Intel Integrated Graphics.";
            };

            nvidiaBusId = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                example = "PCI:1:0:0";
                description = "Bus ID of the NVIDIA dedicated GPU.";
            };
        };
    };

    config = lib.mkIf cfg.enable {
        hardware.graphics.enable = true;
        
        hardware.nvidia.nvidiaPersistenced.enable = true;

        boot.blacklistedKernelModules = [ "nouveau" ];

        hardware.nvidia = {
            package = cfg.package;
            modesetting.enable = true;
            open = false;

            prime = lib.mkIf cfg.prime.enable {
                offload = {
                    enable = true;
                    enableOffloadCmd = true;
                };
                inherit (cfg.prime) intelBusId nvidiaBusId;
            };
        };
    };
}
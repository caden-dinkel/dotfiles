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
        };
    };
}
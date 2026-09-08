{ lib, config, ... }:
let
    cfg = config.myHardware.disk;
in
lib.mkIf cfg.main.swap.enable {
    swap = {
        priority = 2;
        size = cfg.main.swap.size;
        content = {
            type = "swap";
            discardPolicy = "both";
            resumeDevice = false;
        };
    };
}
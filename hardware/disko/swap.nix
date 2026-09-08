{ config, ... }:
let
    cfg = config.myHardware.disk;
in
{
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
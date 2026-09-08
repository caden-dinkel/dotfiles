{
    priority = 1;
    name = "ESP";
    start = "1M";
    end = "1G";
    type = "EF00";
    content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
        mountOptions = [ "umask=0077" ];
    };
}
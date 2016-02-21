object template fstab;

include 'base';
    
prefix "/software/components/nfs/mounts/0";
"device" = "/mydev0";
"mountpoint" = "/mount000";
"fstype" = "nfs";

prefix "/software/components/nfs/mounts/1";
"device" = "mydev1";
"mountpoint" = "/mount1";
"fstype" = "panfs";
"options" = "super,awesome";
"freq" = 5;
"passno" = 100;

prefix "/software/components/nfs/mounts/2";
"device" = "amydev2";
"mountpoint" = "/amount2";
"fstype" = "none";
"options" = "bind";



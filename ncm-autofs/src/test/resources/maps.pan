object template maps;

# mock pkg_repl
function pkg_repl = { null; };

include 'components/autofs/config';

# remove the dependencies
'/software/components/autofs/dependencies' = null;

prefix "/software/components/autofs/maps/map1";
"enabled" = true;
"entries/{/export/map1}" = dict(
    "location", "myserver.mydomain:/export/path1",
    "options", "-fstype=nfs4,nfsvers=4,minorversion=1,rw,soft,tcp,async,noatime,sec=sys",
);
"entries/{/export/map1b}" = dict(
    "location", "myserver.mydomain:/export/path1b",
    "options", "fstype=nfs4,nfsvers=4,minorversion=1,rw,soft,tcp,async,noatime,sec=sys",
);
"mapname" = "/etc/auto.export_map1";
"mountpoint" = "/mymounts/map1";
"options" = "fstype=nfs4,nfsvers=4,minorversion=1,rw,soft,tcp,async,noatime,sec=sys";
"preserve" = false;
"type" = "file";


prefix "/software/components/autofs/maps/map2";
"enabled" = true;
"entries/{/export/map2}" = dict(
    "location", "myserver.mydomain:/export/path2",
    "options", "-fstype=nfs4,nfsvers=4,minorversion=1,rw,soft,tcp,async,noatime,sec=sys",
);
"entries/{/export/map2b}" = dict(
    "location", "myserver.mydomain:/export/path2b",
    "options", "-fstype=nfs4,nfsvers=4,minorversion=1,rw,soft,tcp,async,noatime,sec=sys",
);
"entries/{/export/map2c}" = dict(
    "location", "myserver.mydomain:/export/path2c",
    "options", "-fstype=nfs4,nfsvers=4,minorversion=1,rw,soft,tcp,async,noatime,sec=sys",
);
"entries/{/export/map2d}" = dict(
    "location", "myserver.mydomain:/export/path2d",
    "options", "-fstype=nfs4,nfsvers=4,minorversion=1,rw,soft,tcp,async,noatime,sec=sys",
);
"mapname" = "/etc/auto.export_map2";
"mountpoint" = "/mymounts/map2";
"options" = "-fstype=nfs4,nfsvers=4,minorversion=1,rw,soft,tcp,async,noatime,sec=sys";
"preserve" = true;
"type" = "file";

prefix "/software/components/autofs/conf/autofs";
"timeout" = 300;
"browse_mode" = false;

prefix "/software/components/autofs/conf/amd";
"dismount_interval" = 600;
"autofs_use_lofs" = false;

prefix "/software/components/autofs/conf/mountpoints";
"{/some/mount1}/dismount_interval" = 1200;
"{/some/mount2}/autofs_use_lofs" = true;

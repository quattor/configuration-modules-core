unique template exports2;

prefix "/software/components/metaconfig/services/{/etc/ganesha/ganesha.conf}/contents/exports/0";
"Export_id" = 76;
"Path" = "/gpfs/scratchtest/home/gent";
"Pseudo" = "/user/home/gent";
"Protocols" = list('4');
"Transports" = list("TCP");
"Filesystem_id" = "192.168";
"Tag" = "home";
"NFS_Commit" = true;
"FSAL" = dict("name", "GPFS");

prefix "/software/components/metaconfig/services/{/etc/ganesha/ganesha.conf}/contents/exports/0/CLIENT/0";
"Clients" = list("*.vsc");
"Access_Type" = "RW";
"Squash" = "root_squash";

prefix "/software/components/metaconfig/services/{/etc/ganesha/ganesha.conf}/contents/exports/0/CLIENT/1";
"Clients" = list("*.domain");

prefix "/software/components/metaconfig/services/{/etc/ganesha/ganesha.conf}/contents/exports/1";
"Export_id" = 77;
"Path" = "/gpfs/scratchtest/data/gent";
"Pseudo" = "/user/data/gent";
"Protocols" = list('4');
"Transports" = list("TCP");
"Filesystem_id" = "192.168";
"Tag" = "data";
"NFS_Commit" = true;
"FSAL" = dict("name", "GPFS");

prefix "/software/components/metaconfig/services/{/etc/ganesha/ganesha.conf}/contents/exports/1/CLIENT/0";
"Clients" = list("*.vsc");
"Access_Type" = "RW";
"Squash" = "root_squash";

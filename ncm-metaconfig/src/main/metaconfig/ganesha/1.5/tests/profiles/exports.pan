unique template exports;

prefix "/software/components/metaconfig/services/{/etc/ganesha/ganesha.nfsd.conf}/contents/exports/0";
"Export_Id" = 76;
"Path" = "/some/path";
"Pseudo" = "/some/pseudo/path";
"NFS_Protocols" = list(4);
"Transport_Protocols" = list("TCP");
"Filesystem_id" = "192.167";
"Use_Ganesha_Write_Buffer" = false;
"Use_FSAL_UP" = true;
"FSAL_UP_Type" = "DUMB";
"Cache_Data" = false;
"Tag" = "example_export";
"Use_NFS_Commit" = true;

prefix "/software/components/metaconfig/services/{/etc/ganesha/ganesha.nfsd.conf}/contents/exports/0/clients/0";
"Access" = list("*.sub.domain");
"Access_Type" = "rw";
"Squash" = "root_squash";


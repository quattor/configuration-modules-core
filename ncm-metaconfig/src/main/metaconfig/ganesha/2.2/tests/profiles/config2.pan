object template config2;

variable METACONFIG_GANESHA_VERSION = 'v2';
include 'metaconfig/ganesha/config';

prefix "/software/components/metaconfig/services/{/etc/ganesha/ganesha.conf}/contents/main/CACHEINODE";

"Attr_Expiration_Time" = 120;

"Entries_HWMark" = 1500*256*4;
"LRU_Run_Interval" = 90;
"FD_HWMark_Percent" = 60;
"FD_LWMark_Percent" = 20;
"FD_Limit_Percent" = 90;
"Reaper_Work" = 1500;

prefix "/software/components/metaconfig/services/{/etc/ganesha/ganesha.conf}/contents/main/NFS_CORE_PARAM";
"Nb_Worker" = 128*4;
"MNT_Port" = 32767;
"NLM_Port" = 32769;
"RQOTA_Port" = null; # no rqouta on gpfs
"Clustered" = true;

include 'exports2';

object template multipath;

include 'metaconfig/devicemapper/multipath';

prefix "/software/components/metaconfig/services/{/etc/multipath.conf}/contents/defaults";
'path_checker' = 'hp_sw';
'prio' = 'hp_sw';
'user_friendly_names' = true;
'path_grouping_policy' = 'group_by_prio';
'failback' = 'immediate';
'detect_prio' = true;
'path_selector' = list('round-robin', 0);
'features' = list(1, list('queue_if_no_path'));
'max_sectors_kb' = 1024;

prefix "/software/components/metaconfig/services/{/etc/multipath.conf}/contents";
"multipaths/0/wwid" = "3600c0ff00012c51bacb68a4e01000000";
"multipaths/0/alias" = "p21as1ScrD";
"multipaths/1/wwid" = "3600c0ff00012c51b92b68a4e01000000";
"multipaths/1/alias" = "p21as1ScrM";
"multipaths/2/wwid" = "3600c0ff00012c51b9eb68a4e01000000";
"multipaths/2/alias" = "p21as1SofD";


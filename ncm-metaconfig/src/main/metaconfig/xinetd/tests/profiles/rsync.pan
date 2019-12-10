object template rsync;

include 'metaconfig/xinetd/services/rsync';

prefix "/software/components/metaconfig/services/{/etc/xinetd.d/rsync}/contents";

"options/log_on_success" = list("HOST", "DURATION", "TRAFFIC");
"options/log_on_failure" = list("HOST", "USERID");

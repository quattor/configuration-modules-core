unique template metaconfig/xinetd/services/time-stream;

include 'metaconfig/xinetd/schema';

bind "/software/components/metaconfig/services/{/etc/xinetd.d/time-stream}/contents" = xinetd_conf;

"/software/components/metaconfig/services/{/etc/xinetd.d/time-stream}" = create('metaconfig/xinetd/metaconfig');

prefix "/software/components/metaconfig/services/{/etc/xinetd.d/time-stream}/contents";
"servicename" = "time";
"options/disable" = false;
"options/id" = "time-stream";
"options/type" = list("INTERNAL");
"options/wait"= false;
"options/socket_type" = "stream";

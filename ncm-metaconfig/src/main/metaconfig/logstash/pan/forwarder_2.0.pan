unique template metaconfig/logstash/forwarder_2.0;

variable METACONFIG_LOGSTASH_VERSION = 'v2.0';
include format('metaconfig/logstash/schema_%s', METACONFIG_LOGSTASH_VERSION);

bind "/software/components/metaconfig/services/{/etc/logstash-forwarder.conf}/contents" = type_logstash_forwarder;

prefix "/software/components/metaconfig/services/{/etc/logstash-forwarder.conf}";
"daemons/logstash-forwarder" = "restart";
"owner" = "root";
"group" = "root";
"mode" = 0640;
"module" = format("logstash/forwarder");

unique template metaconfig/logstash/forwarder_1.2;

include 'metaconfig/logstash/schema_1.2';

bind "/software/components/metaconfig/services/{/etc/logstash-forwarder.conf}/contents" = type_logstash_forwarder;

prefix "/software/components/metaconfig/services/{/etc/logstash-forwarder.conf}";
"daemons/logstash-forwarder" = "restart";
"owner" = "root";
"group" = "root";
"mode" = 0640;
"module" = format("logstash/forwarder");

unique template metaconfig/logstash/forwarder;

include 'metaconfig/logstash/schema';

bind "/software/components/metaconfig/services/{/etc/logstash-forwarder}/contents" = type_logstash_forwarder;

prefix "/software/components/metaconfig/services/{/etc/logstash-forwarder}";
"daemon/0" = "logstash-forwarder";
"owner" = "root";
"group" = "root";
"mode" = 0640;
"module" = format("logstash/forwarder");


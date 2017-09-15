unique template metaconfig/logstash/daemon_5.0;

include 'metaconfig/logstash/schema_5.0';

bind "/software/components/metaconfig/services/{/etc/logstash/logstash.yml}/contents" = type_logstash_yml;

prefix "/software/components/metaconfig/services/{/etc/logstash/logstash.yml}";
"daemons/logstash" = "restart";
"owner" = "root";
"group" = "root";
"mode" = 0644;
"module" = "yaml";


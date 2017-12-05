unique template metaconfig/logstash/config_2.0;

include 'metaconfig/logstash/schema_2.0';

bind "/software/components/metaconfig/services/{/etc/logstash/conf.d/logstash.conf}/contents" = type_logstash_20;

prefix "/software/components/metaconfig/services/{/etc/logstash/conf.d/logstash.conf}";
"daemons/logstash" = "restart";
"owner" = "root";
"group" = "root";
"mode" = 0644;
"module" = format("logstash/%s/main" , METACONFIG_LOGSTASH_VERSION);

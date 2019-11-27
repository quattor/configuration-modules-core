unique template metaconfig/kafka/config;

include 'metaconfig/kafka/schema';

bind "/software/components/metaconfig/services/{/etc/kafka/server.properties}/contents" = kafka_server_properties;

prefix "/software/components/metaconfig/services/{/etc/kafka/server.properties}";
"mode" = 0644;
"owner" = "root";
"group" = "root";
"daemons/kafka" = "restart";
"module" = "properties";

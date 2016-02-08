unique template metaconfig/beats/filebeat;

include 'metaconfig/beats/schema';

bind "/software/components/metaconfig/services/{/etc/filebeat/filebeat.yml}/contents" = beats_filebeat_service;

prefix "/software/components/metaconfig/services/{/etc/filebeat/filebeat.yml}";
"daemons/filebeat" = "restart";
"module" = "yaml";
"mode" = 0644;

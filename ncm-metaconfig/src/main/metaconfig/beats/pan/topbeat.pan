unique template metaconfig/beats/topbeat;

include 'metaconfig/beats/schema';

bind "/software/components/metaconfig/services/{/etc/topbeat/topbeat.yml}/contents" = beats_topbeat_service;

prefix "/software/components/metaconfig/services/{/etc/topbeat/topbeat.yml}";
"daemons/topbeat" = "restart";
"module" = "yaml";
"mode" = 0644;

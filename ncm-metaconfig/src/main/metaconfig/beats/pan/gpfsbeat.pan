unique template metaconfig/beats/gpfsbeat;

include 'metaconfig/beats/schema';

bind "/software/components/metaconfig/services/{/etc/gpfsbeat/gpfsbeat.yml}/contents" = beats_gpfsbeat_service;
prefix "/software/components/metaconfig/services/{/etc/gpfsbeat/gpfsbeat.yml}";
"daemons/gpfsbeat" = "restart";
"module" = "yaml";
"mode" = 0644;

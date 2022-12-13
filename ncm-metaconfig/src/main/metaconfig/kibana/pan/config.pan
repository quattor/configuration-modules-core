unique template metaconfig/kibana/config;

variable METACONFIG_KIBANA_VERSION ?= "8.1";
include 'metaconfig/kibana/schema';

bind "/software/components/metaconfig/services/{/etc/kibana/kibana.yml}/contents" = kibana_service;

prefix "/software/components/metaconfig/services/{/etc/kibana/kibana.yml}";
"daemons/kibana" = "restart";
"module" = "yaml";
"mode" = 0644;

unique template metaconfig/carbon-relay-ng/config;

include 'metaconfig/carbon-relay-ng/schema';

bind "/software/components/metaconfig/services/{/etc/carbon-relay-ng.ini}/contents" = carbon_relay_ng_service;

prefix "/software/components/metaconfig/services/{/etc/carbon-relay-ng.ini}";
"daemon" = "carbon-relay-ng";
"module" = "carbon-relay-ng/main";

unique template metaconfig/dellnetworking/config;

include 'metaconfig/dellnetworking/schema';

bind "/software/components/metaconfig/services/{/dellnetworking.cfg}/contents" = dellnetworking_config;

prefix "/software/components/metaconfig/services/{/dellnetworking.cfg}";
"module" = "dellnetworking/config";


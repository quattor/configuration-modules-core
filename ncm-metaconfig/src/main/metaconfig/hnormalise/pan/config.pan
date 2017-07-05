unique template metaconfig/hnormalise/config;

include 'metaconfig/hnormalise/schema';

bind "/software/components/metaconfig/services/{/etc/hnormalise.yaml}/contents" = type_hnormalise;

prefix "/software/components/metaconfig/services/{/etc/hnormalise.yaml}";
"daemons/hnormalise" = "restart";
"owner" = "root";
"group" = "root";
"mode" = 0644;
"module" = "yaml";

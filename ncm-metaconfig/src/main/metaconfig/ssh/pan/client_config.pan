unique template metaconfig/ssh/client_config;

include 'metaconfig/ssh/schema';

bind "/software/components/metaconfig/services/{/etc/ssh/ssh_config}/contents" = ssh_config_file;

prefix "/software/components/metaconfig/services/{/etc/ssh/ssh_config}";
"module" = "ssh/client";

unique template metaconfig/ssh_config/config;

include 'metaconfig/ssh_config/schema';

bind "/software/components/metaconfig/services/{/etc/ssh/ssh_config}/contents" = ssh_config_file;

prefix "/software/components/metaconfig/services/{/etc/ssh/ssh_config}";
"module" = "ssh_config/main";

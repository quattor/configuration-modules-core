unique template metaconfig/ssh/server_config;

include 'metaconfig/ssh/schema';

bind "/software/components/metaconfig/services/{/etc/ssh/sshd_config}/contents" = sshd_config_file;

prefix "/software/components/metaconfig/services/{/etc/ssh/sshd_config}";
"module" = "ssh/server";
"commands/test" = "/usr/sbin/sshd -t -f /dev/stdin";
"daemons/sshd" = "restart";

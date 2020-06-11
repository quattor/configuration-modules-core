unique template metaconfig/ssh/server_config;

include 'metaconfig/ssh/schema';

bind "/software/components/metaconfig/services/{/etc/ssh/sshd_config}/contents" = sshd_config_file;

prefix "/software/components/metaconfig";

final "commands/sshd_test_stdin" = "/usr/sbin/sshd -t -f /dev/stdin";

prefix "services/{/etc/ssh/sshd_config}";
"module" = "ssh/server";
"actions/test" = "sshd_test_stdin";
"daemons/sshd" = "restart";

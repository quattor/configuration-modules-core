unique template metaconfig/ssh/server_config;

include 'metaconfig/ssh/schema';

bind "/software/components/metaconfig/services/{/etc/ssh/sshd_config}/contents" = sshd_config_file;

# since final locks the whole path, bind it to a fix value and set it as default too
#    TODO: support in compiler
bind "/software/components/metaconfig/commands/sshd_test_stdin" =
    string = "/usr/sbin/sshd -t -f /dev/stdin" with SELF == "/usr/sbin/sshd -t -f /dev/stdin";

prefix "/software/components/metaconfig/services/{/etc/ssh/sshd_config}";
"module" = "ssh/server";
"actions/test" = "sshd_test_stdin";
"daemons/sshd" = "restart";

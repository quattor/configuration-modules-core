# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/tftpd/config-rpm;
include components/tftpd/schema;

# Common settings
#"/software/components/tftpd/dependencies/pre" = list("spma");
"/software/components/tftpd/active" = true;
"/software/components/tftpd/dispatch" ?= true;

# Implemented options (not all options the demon takes are implemented)
# shall xinetd disable this service?
"/software/components/tftpd/disable"     = "no";
# Is the service single-threaded (yes) or multi-threaded (no)
"/software/components/tftpd/wait"        = "yes";
# Under which account will the service run?
"/software/components/tftpd/user"        = "root";
# The binary to be launched
"/software/components/tftpd/server"      = "/usr/sbin/in.tftpd";
# arguments to be passed to the server
"/software/components/tftpd/server_args" = "-s /tftpboot";

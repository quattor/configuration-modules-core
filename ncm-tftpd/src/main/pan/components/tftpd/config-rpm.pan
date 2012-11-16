# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/${project.artifactId}/config-rpm;
include {'components/${project.artifactId}/schema'};

# Common settings
#"/software/components/${project.artifactId}/dependencies/pre" = list("spma");
"/software/components/${project.artifactId}/active" = true;
"/software/components/${project.artifactId}/dispatch" ?= true;

# Implemented options (not all options the demon takes are implemented)
# shall xinetd disable this service?
"/software/components/${project.artifactId}/disable"     = "no";
# Is the service single-threaded (yes) or multi-threaded (no)
"/software/components/${project.artifactId}/wait"        = "yes";
# Under which account will the service run?
"/software/components/${project.artifactId}/user"        = "root";
# The binary to be launched
"/software/components/${project.artifactId}/server"      = "/usr/sbin/in.tftpd";
# arguments to be passed to the server
"/software/components/${project.artifactId}/server_args" = "-s /tftpboot";
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

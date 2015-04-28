unique template metaconfig/perfsonar/lookup/daemon/config;

include 'metaconfig/perfsonar/lookup/daemon/schema';

bind "/software/components/metaconfig/services/{/opt/perfsonar_ps/lookup_service/etc/daemon.conf}/contents" = ls_daemon;

prefix "/software/components/metaconfig/services/{/opt/perfsonar_ps/lookup_service/etc/daemon.conf}";

"module" = "perfsonar/lookup_service";
"owner" = "root";
"group" = "root";
"daemons/lookup_service" = "restart";
"backup" = ".old";

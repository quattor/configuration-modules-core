unique template metaconfig/perfsonar/lookup/registration/config;

include 'metaconfig/perfsonar/lookup/registration/schema';

bind "/software/components/metaconfig/services/{/opt/perfsonar_ps/ls_registration_daemon/etc/ls_registration_daemon.conf}/contents" = ls_registration;

prefix "/software/components/metaconfig/services/{/opt/perfsonar_ps/ls_registration_daemon/etc/ls_registration_daemon.conf}";

"module" = "general";
"owner" = "root";
"group" = "root";
"daemons/ls_registration_daemon" = "restart";

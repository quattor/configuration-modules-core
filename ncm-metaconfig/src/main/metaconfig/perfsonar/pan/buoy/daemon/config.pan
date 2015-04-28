unique template metaconfig/perfsonar/buoy/daemon/config;

include 'metaconfig/perfsonar/buoy/daemon/schema';

bind "/software/components/metaconfig/services/{/opt/perfsonar_ps/perfsonarbuoy_ma/etc/daemon.conf}/contents" = buoydaemon;

prefix "/software/components/metaconfig/services/{/opt/perfsonar_ps/perfsonarbuoy_ma/etc/daemon.conf}";

"daemons/perfsonarbuoy_ma" = "restart";
"owner" = "root";
"group" = "root";
"module" = "perfsonar/ma";

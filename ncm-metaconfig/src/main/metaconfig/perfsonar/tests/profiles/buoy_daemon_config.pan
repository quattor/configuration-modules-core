object template buoy_daemon_config;

include 'metaconfig/perfsonar/buoy/daemon/config';


prefix "/software/components/metaconfig/services/{/opt/perfsonar_ps/perfsonarbuoy_ma/etc/daemon.conf}/contents";

"ports/0/endpoint/0/name" = "/perfsonar_PS/services/pSB";
"ports/0/endpoint/0/buoy/service_description" = "PerfSONAR measurement archive (MA) for our_project";

object template lookup_daemon;

include 'metaconfig/perfsonar/lookup/daemon/config';

prefix "/software/components/metaconfig/services/{/opt/perfsonar_ps/lookup_service/etc/daemon.conf}/contents/port/0/endpoint/0";
"name" = "/perfsonar_PS/services/hLS";
"gls/0/service_name" = "PerfSONAR gLS at HERE for MYSITE";
"gls/0/service_description" = "MYSITE lookup service at HERE";

prefix "/software/components/metaconfig/services/{/opt/perfsonar_ps/lookup_service/etc/daemon.conf}/contents";
"port/0/portnum" = 9995;

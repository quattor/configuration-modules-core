unique template metaconfig/snmp/snmp;

include 'metaconfig/snmp/schema';

bind "/software/components/metaconfig/services/{/etc/snmp/snmp.conf}/contents" = snmp_snmp_conf;

prefix "/software/components/metaconfig/services/{/etc/snmp/snmp.conf}";
"owner" = "root";
"group" = "root";
"module" = "snmp/snmp";
"mode" = 0644;

unique template metaconfig/snmp/snmpd;

include 'metaconfig/snmp/schema';

bind "/software/components/metaconfig/services/{/etc/snmp/snmpd.conf}/contents" = snmp_snmpd_conf;

prefix "/software/components/metaconfig/services/{/etc/snmp/snmpd.conf}";
"owner" = "root";
"group" = "root";
"module" = "snmp/snmpd";
"mode" = 0644;
"daemon" = list('snmpd');

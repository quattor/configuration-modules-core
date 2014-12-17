unique template metaconfig/snmp/snmptrapd;

include 'metaconfig/snmp/schema';

bind "/software/components/metaconfig/services/{/etc/snmp/snmptrapd.conf}/contents" = snmp_snmptrapd_conf;

prefix "/software/components/metaconfig/services/{/etc/snmp/snmptrapd.conf}";
"owner" = "root";
"group" = "root";
"module" = "snmp/snmptrapd";
"mode" = 0644;
"daemon" = list('snmptrapd');

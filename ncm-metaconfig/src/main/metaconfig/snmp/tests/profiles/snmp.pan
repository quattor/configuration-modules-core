object template snmp;

include 'metaconfig/snmp/snmp';

prefix "/software/components/metaconfig/services/{/etc/snmp/snmp.conf}/contents";
"mibs" = list('ALL');
"mibdirs" = list("/some/path", "/usr/share/snmp/mibs");

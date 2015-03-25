object template snmptrapd;

# unbound, should be available already
# just for this test
prefix "/software/components/metaconfig/services/{/etc/snmp/snmpd.conf}/contents/main";
"authcommunity" = 'log,execute public';

include 'metaconfig/snmp/snmptrapd';

prefix "/software/components/metaconfig/services/{/etc/snmp/snmptrapd.conf}/contents";
"main/authCommunity" = value("/software/components/metaconfig/services/{/etc/snmp/snmpd.conf}/contents/main/authcommunity");


"traphandle" = {
    ips=list('1.2.3.4','1.2.3.5');
    exe='/usr/bin/handle_nsca_traps.py';
    append(format('%s %s -T %s -t %s,%s','1.3.6.1.4.1.2.6.212*',exe,'gpfs',ips[0],ips[1]));
    append(format('%s %s -t %s,%s','default',exe,ips[0],ips[1]));
};

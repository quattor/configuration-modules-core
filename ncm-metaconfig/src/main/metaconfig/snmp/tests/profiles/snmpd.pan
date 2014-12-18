object template snmpd;

# unbound, should be available already
# just for this test
"/system/rootmail" = "my.email@address";

include 'metaconfig/snmp/snmpd';

prefix "/software/components/metaconfig/services/{/etc/snmp/snmpd.conf}/contents";
"group" = list(
    'notConfigGroup v1           notConfigUser',
    'notConfigGroup v2c           notConfigUser',
);

prefix "/software/components/metaconfig/services/{/etc/snmp/snmpd.conf}/contents/main";
"access" = 'notConfigGroup ""      any       noauth    exact  systemview none none';
"agentXRetries" = 10;
"agentXSocket" = 'tcp:localhost:705';
"agentXTimeout" = 20;
"authcommunity" = 'log,execute public';
"com2sec" = 'notConfigUser  default       public';
"master" = 'agentx';
"pass" = '.1.3.6.1.4.1.4413.4.1 /usr/bin/ucd5820stat';
"trap2sink" = 'localhost';
"view" = 'systemview    included   1.3.6.1';
"sysLocation" = "mysite";
"sysContact" = value("/system/rootmail");

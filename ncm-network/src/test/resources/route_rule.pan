object template route_rule;

include 'simple_base_profile';

prefix "/system/network/interfaces/eth0";
"route/0" = dict("address", "1.2.3.4");
"route/1" = dict("address", "1.2.3.5", "netmask", "255.255.255.0");
"route/2" = dict("address", "1.2.3.6", "netmask", "255.0.0.0", "gateway", "4.3.2.1");
"route/3" = dict("address", "1.2.3.7", "prefix", 16, "gateway", "4.3.2.2");
"route/4" = dict("command", "something arbitrary");
"route/5" = dict("address", "::4", "prefix", 75);
"route/6" = dict("address", "::5", "prefix", 76, "gateway", "4::1");
"route/7" = dict("command", "something arbitrary with :");

"rule/0" = dict("command", "something");
"rule/1" = dict("command", "something with ::");
"rule/2" = dict("command", "more");
"rule/3" = dict("command", "more ::");

# test legacy format conversion
"/system/network/interfaces/eth1" = create("defaultinterface");
prefix "/system/network/interfaces/eth1";
"route/0" = dict("address", "1.2.3.4");
"defroute" = false;

# test route on vlan
"/system/network/interfaces/vlan0" = create("defaultinterface");
prefix "/system/network/interfaces/vlan0";
"device" = "eth0.123";
"physdev" = "eth0";
"route/0" = dict("address", "1.2.3.4");

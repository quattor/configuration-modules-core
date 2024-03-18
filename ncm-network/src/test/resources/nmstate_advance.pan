object template nmstate_advance;

include 'simple_base_profile';
include 'components/network/config-nmstate';

# additional interface testing for nmstate.
"/system/network/interfaces/eth1" = create("dhcpinterface");
"/hardware/cards/nic/eth1/hwaddr" = "6e:a5:1b:55:77:0b";
"/system/network/interfaces/bond0" = create("bondinterface");
"/hardware/cards/nic/eth2/hwaddr" = "6e:a5:1b:55:77:0c";
"/system/network/interfaces/eth2/master" = "bond0";
"/hardware/cards/nic/eth3/hwaddr" = "6e:a5:1b:55:77:0d";
"/system/network/interfaces/eth3/master" = "bond0";

# routes and rules
prefix "/system/network/routing_table";
"outside" = 3;
"space" = 4;

prefix "/system/network/interfaces/eth0";
"route/0" = dict("address", "1.2.3.4");
"route/1" = dict("address", "1.2.3.5", "netmask", "255.255.255.0");
"route/2" = dict("address", "1.2.3.6", "netmask", "255.0.0.0", "gateway", "4.3.2.1");
"route/3" = dict("address", "1.2.3.7", "prefix", 16, "gateway", "4.3.2.2");
"route/4" = dict("address", "default", "gateway", "4.3.2.3", "table", "outside");

"rule/0" = dict("to", "1.2.3.4/24", "not", true, "table", "space");

# test vlan interface and route on vlan
"/system/network/interfaces/eth0.123" = create("vlaninterface");
"/hardware/cards/nic/eth0/hwaddr" = "6e:a5:1b:55:77:0a";
prefix "/system/network/interfaces/eth0.123";
"physdev" = "eth0";
"route/0" = dict("address", "1.2.3.4");

# test vlan interface route on vlan for backward compatibily with network.pm
"/system/network/interfaces/vlan0" = create("defaultinterface");
prefix "/system/network/interfaces/vlan0";
"device" = "eth0.123";
"physdev" = "eth0";
"route/0" = dict("address", "1.2.3.4");
object template nmstate_advance;

variable QUATTOR_TYPES_NETWORK_BACKEND = 'nmstate';

include 'simple_base_profile';
include 'components/network/config-nmstate';

"/system/network/default_gateway" = "4.3.2.254";
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
"route/5" = dict("address", "default", "gateway", "4.3.2.3", "table", "outside",
"cwnd", 100, "initcwnd", 50, "initrwnd", 40);

"rule/0" = dict("to", "1.2.3.4/24", "not", true, "table", "space");

# test vlan interface and route on vlan
"/system/network/interfaces/eth0.123" = create("vlaninterface");
"/hardware/cards/nic/eth0/hwaddr" = "6e:a5:1b:55:77:0a";
prefix "/system/network/interfaces/eth0.123";
"physdev" = "eth0";
"route/0" = dict("address", "1.2.3.4");

# test vlan interface vlan0 (interface ID=0/false, no VLAN ID in interface name)
"/system/network/interfaces/vlan0" = create("vlaninterface");
prefix "/system/network/interfaces/vlan0";
"device" = "eth0.123";
"physdev" = "eth0";
"route/0" = dict("address", "1.2.3.4");

# test vlan interface vlan1.123 (interface ID=1/true, VLAN ID in interface name)
"/system/network/interfaces/vlan1.123" = create("vlaninterface");
prefix "/system/network/interfaces/vlan1.123";
"physdev" = "eth0";
"route/0" = dict("address", "1.2.3.4");

# test vlan interface vlan.456 (no partition number, VLAN ID in interface name)
"/system/network/interfaces/vlan.456" = create("vlaninterface");
prefix "/system/network/interfaces/vlan.456";
"physdev" = "eth0";
"route/0" = dict("address", "1.2.3.4");

# test ib interface (default and with pkey)
prefix "/system/network/interfaces/ib0";
"ip" = "10.11.12.13";
"netmask" = "255.255.255.0";
"broadcast" = "10.11.12.255";
"type" = "Infiniband";

prefix "/system/network/interfaces/ib1.12345";
"ip" = "10.11.15.13";
"netmask" = "255.255.255.0";
"broadcast" = "10.11.15.255";
"type" = "Infiniband";

# Test creating dummy interface. aka loopback interface needed for vip, such as zebra.
"/system/network/manage_vips" = true;
prefix "/system/network/vips/myvip";
"fqdn" = "myvip.test.com";
"ip" = "4.3.2.10";
"interfaces/0" = "eth0";

# create aliases interfaces
"/hardware/cards/nic/eth4/hwaddr" = "6e:a5:1b:55:77:0e";
prefix "/system/network/interfaces/eth4";
"ip" = "4.3.2.11";
"netmask" = "255.255.255.0";
"broadcast" = "4.3.2.255";
"aliases/dba/broadcast" = "4.3.2.255";
"aliases/dba/fqdn" = "host-alias1.quattor.com";
"aliases/dba/ip" = "4.3.2.12";
"aliases/dba/netmask" = "255.255.255.0";

# ovs construction
"/system/network/interfaces/bond1" = dict(
    "driver", "bonding",
    "type", "OVSPort",
    "ovs_bridge", "br100",
);

"/hardware/cards/nic/eth10/hwaddr" = "6e:a5:1b:55:77:10";
"/system/network/interfaces/eth10/master" = "bond1";

"/hardware/cards/nic/eth11/hwaddr" = "6e:a5:1b:55:77:11";
"/system/network/interfaces/eth11/master" = "bond1";

"/system/network/interfaces/br100" = dict(
    "type", "OVSBridge",
    "bootproto", "static",
);

"/system/network/interfaces/eth1000" = dict(
    "broadcast", '4.3.2.255',
    "ip", '4.3.2.1',
    "netmask", '255.255.255.0',
    "type", "OVSIntPort",
    "ovs_bridge", "br100",
);

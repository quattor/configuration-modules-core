object template vnet_ovsbr0;

include 'components/opennebula/schema';

bind "/metaconfig/contents/vnet/node3.cubone.os" = opennebula_vnet;

"/metaconfig/module" = "vnet";

prefix "/metaconfig/contents/vnet/node3.cubone.os";
"bridge" = "br100";
"bridge_ovs" = "ovsbr0";
"gateway" = "10.141.3.250";
"dns" = "10.141.3.250";
"network_mask" = "255.255.0.0";
"vlan" = true;
"vlan_id" = 0;
"vn_mad" = "ovswitch";
"ar" = dict(
    "type", "IP4",
    "ip", "10.141.14.100",
    "size", 29,
);
"labels" = list("quattor", "quattor/vlans");

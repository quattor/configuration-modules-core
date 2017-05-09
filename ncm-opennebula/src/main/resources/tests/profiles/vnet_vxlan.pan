object template vnet_vxlan;

include 'components/opennebula/schema';

bind "/metaconfig/contents/vnet/vxlanpool" = opennebula_vnet;

"/metaconfig/module" = "vnet";

prefix "/metaconfig/contents/vnet/vxlanpool";
"gateway" = "10.1.20.250";
"dns" = "10.1.20.1";
"network_mask" = "255.255.255.0";
"vlan" = true;
"vlan_id" = 10;
"vn_mad" = "vxlan";
"ar" = dict(
    "type", "IP4",
    "ip", "10.1.20.100",
    "size", 100,
);
"phydev" = "ib0";
"filter_ip_spoofing" = true;
"filter_mac_spoofing" = true;
"labels" = list("quattor", "quattor/vlans");
"permissions/owner" = "lsimngar";
"permissions/group" = "users";
"permissions/mode" = 0440;

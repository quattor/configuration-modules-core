object template ovs;

include 'pan/types';
include 'components/network/core-schema';

bind "/system/network" = structure_network;

"/system/network" = create("defaultnetwork");

"/system/network/interfaces/br100" = dict(
    "broadcast", "4.3.2.255",
    "ip", "4.3.2.1",
    "netmask", "255.255.255.0",
    "type", "OVSBridge",
    "bootproto", "static",
);

"/system/network/interfaces/eth0" = dict(
    "type", "OVSPort",
    "ovs_bridge", "br100",
    "ovs_opts", "tag=50",
    "ovs_extra", "whatever",
    "bootproto", "none",
);

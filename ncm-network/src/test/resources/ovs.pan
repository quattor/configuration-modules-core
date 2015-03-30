object template ovs;

"/system/network" = create("defaultnetwork");

"/system/network/interfaces/br-ex" = nlist(
    "broadcast",    "4.3.2.255",
    "ip",           "4.3.2.1",
    "netmask",      "255.255.255.0",
    "type",         "OVSBridge",
    "bootproto",    "static",
);

"/system/network/interfaces/eth0" = nlist(
    "type" ,        "OVSPort",
    "ovs_bridge",   "br-ex",
    "bootproto",    "none",
);

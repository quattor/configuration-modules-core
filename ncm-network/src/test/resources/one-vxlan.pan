object template one-vxlan;

@{example opennebula vxlan+bridge
    bridge named vxlan[0-9]
    interface is just tagged like vlan
}

include 'pan/types';
include 'components/network/core-schema';

bind "/system/network" = structure_network;

"/system/network" = create("defaultnetwork");

"/system/network/interfaces/ib0" = dict(
    "broadcast", "4.3.2.255",
    "ip", "4.3.2.1",
    "netmask", "255.255.255.0",
    "bootproto", "static",
);

# vxlan interface
"/system/network/interfaces" = {
    vni = 4 * 256 + 10; # to make 4.10
    br = format("vxlan%d", vni);
    mc_base = ip4_to_long("239.0.0.0");
    # confusing much
    SELF[format("vxlan%d", vni)] = dict(
        "physdev", "ib0",
        "device", format("ib0.%d", vni),
        "bridge", br,
        "plugin", dict(
            "vxlan", dict(
                "vni", vni,
                "group", long_to_ip4(mc_base[0] + vni),
            ),
        ),
    );
    SELF[format("br%d", vni)] = dict(
        "type", "Bridge",
        "device", br,
    );
    SELF;
};

# this makes no real sense, only to test remote/local
"/system/network/interfaces/vxlan123" = dict(
    "physdev", "ib0",
    "plugin", dict(
        "vxlan", dict(
            "local", "9.8.7.6",
            "remote", "9.8.7.5",
            "gbp", true,
            "dstport", 1234,
        ),
    ),
);
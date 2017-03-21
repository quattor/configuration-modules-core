# This should be included from quattor/schema

declaration template components/network/core-schema;

include 'pan/types';
include 'quattor/functions/network';

@documentation{
    Route
}
type structure_route = {
    "address" ? type_ip
    "netmask" ? type_ip
    "gateway" ? type_ip
};

@documentation{
    Interface alias
}
type structure_interface_alias = {
    "ip" ? type_ip
    "netmask" : type_ip
    "broadcast" ? type_ip
    "fqdn" ? type_fqdn
};

@documentation{
    Describes the bonding options for configuring channel bonding on EL5 and similar.
}
type structure_bonding_options = {
    "mode" : long(0..6)
    "miimon" : long
    "updelay" ? long
    "downdelay" ? long
    "primary" ? valid_interface
    "lacp_rate" ? long(0..1)
    "xmit_hash_policy" ? string with match (SELF, '^(0|1|2|layer(2|2\+3|3\+4))$')
} with {
    if ( SELF['mode'] == 1 || SELF['mode'] == 5 || SELF['mode'] == 6 ) {
        if ( ! exists(SELF["primary"]) ) {
            error("Bonding configured but no primary is defined.");
        };
    } else {
        if ( exists(SELF["primary"]) ) {
            error("Primary is defined but this is not allowed with this bonding mode.");
        };
    };
    true;
};

@documentation{
    describes the bridging options
    (the parameters for /sys/class/net/<br>/brport)
}
type structure_bridging_options = {
    "bpdu_guard" ? long
    "flush" ? long
    "hairpin_mode" ? long
    "multicast_fast_leave" ? long
    "multicast_router" ? long
    "path_cost" ? long
    "priority" ? long
    "root_block" ? long
};

@documentation{
    interface ethtool offload
}
type structure_ethtool_offload = {
    "rx" ? string with match (SELF, '^(on|off)$')
    "tx" ? string with match (SELF, '^(on|off)$')
    @{Set the TCP segment offload parameter to "off" or "on"}
    "tso" ? string with match (SELF, '^(on|off)$')
    "gro" ? string with match (SELF, '^(on|off)$')
};

@documentation{
    Set the ethernet transmit or receive buffer ring counts.
    See ethtool --show-ring for the values.
}
type structure_ethtool_ring = {
    "rx" ? long
    "tx" ? long
    "rx-mini" ? long
    "rx-jumbo" ? long
};

@documentation{
    ethtool wol p|u|m|b|a|g|s|d...
    from the man page
        Sets Wake-on-LAN options.  Not all devices support this.  The argument to this option is a string
        of characters specifying which options to enable.
            p  Wake on phy activity
            u  Wake on unicast messages
            m  Wake on multicast messages
            b  Wake on broadcast messages
            a  Wake on ARP
            g  Wake on MagicPacket(tm)
            s  Enable SecureOn(tm) password for MagicPacket(tm)
            d  Disable (wake on nothing).  This option clears all previous option
}
type structure_ethtool_wol = string with match (SELF, '^[pumbagsd]+$');

@documentation{
    ethtool
}
type structure_ethtool = {
    "wol" ? structure_ethtool_wol
    "autoneg" ? string with match (SELF, '^(on|off)$')
    "duplex" ? string with match (SELF, '^(half|full)$')
    "speed" ? long
};

@documentation{
    interface
}
type structure_interface = {
    "ip" ? type_ip
    "gateway" ? type_ip
    "netmask" ? type_ip
    "broadcast" ? type_ip
    "driver" ? string
    "bootproto" ? string
    "onboot" ? string
    "type" ? string with match(SELF, '^(Ethernet|Bridge|Tap|xDSL|OVS(Bridge|Port|IntPort|Bond|Tunnel|PatchPort))$')
    "device" ? string
    "master" ? string
    "mtu" ? long
    @{Routes for this interface.
      These values are used to generate the /etc/sysconfig/network-scripts/route-<interface> files
      as used by ifup-routes when using ncm-network.}
    "route" ? structure_route[]
    @{Aliases for this interface.
      These values are used to generate the /etc/sysconfig/network-scripts/ifcfg-<interface>:<key> files
      as used by ifup-aliases when using ncm-network.}
    "aliases" ? structure_interface_alias{}
    @{Explicitly set the MAC address. The MAC address is taken from /hardware/cards/nic/<interface>/hwaddr.}
    "set_hwaddr" ? boolean
    "bridge" ? valid_interface
    "bonding_opts" ? structure_bonding_options

    "offload" ? structure_ethtool_offload
    "ring" ? structure_ethtool_ring
    "ethtool" ? structure_ethtool

    "vlan" ? boolean
    "physdev" ? valid_interface

    "fqdn" ? string
    "network_environment" ? string
    "network_type" ? string
    "nmcontrolled" ? boolean

    "linkdelay" ? long # LINKDELAY
    "stp" ? boolean # enable/disable stp on bridge (true: STP=on)
    "delay" ? long # brctl setfd DELAY
    "bridging_opts" ? structure_bridging_options

    "bond_ifaces" ? string[]
    "ovs_bridge" ? valid_interface
    "ovs_extra" ? string
    "ovs_opts" ? string # See ovs-vswitchd.conf.db(5) for documentation
    "ovs_patch_peer" ? string
    "ovs_tunnel_opts" ? string # See ovs-vswitchd.conf.db(5) for documentation
    "ovs_tunnel_type" ? string with match(SELF, '^(gre|vxlan)$')

    "ipv4_failure_fatal" ? boolean
    "ipv6_autoconf" ? boolean
    "ipv6_failure_fatal" ? boolean
    "ipv6_mtu" ? long(1280..65536)
    "ipv6_privacy" ? string with match(SELF, '^rfc3041$')
    "ipv6_rtr" ? boolean
    "ipv6addr" ? type_network_name
    "ipv6addr_secondaries" ? type_network_name[]
    "ipv6init" ? boolean

} with {
    if ( exists(SELF['ovs_bridge']) && exists(SELF['type']) && SELF['type'] == 'OVSBridge') {
        error("An OVSBridge interface cannot have the ovs_bridge option defined");
    };
    if ( exists(SELF['ovs_tunnel_type']) && (!exists(SELF['type']) || SELF['type'] != 'OVSTunnel')) {
        error("ovs_tunnel_bridge is defined but the type of interface is not defined as OVSTunnel");
    };
    if ( exists(SELF['ovs_tunnel_opts']) && (!exists(SELF['type']) || SELF['type'] != 'OVSTunnel')) {
        error("ovs_tunnel_opts is defined but the type of interface is not defined as OVSTunnel");
    };
    if ( exists(SELF['ovs_patch_peer']) && (!exists(SELF['type']) || SELF['type'] != 'OVSPatchPort')) {
        error("ovs_patch_peer is defined but the type of interface is not defined as OVSPatchPort");
    };
    if ( exists(SELF['bond_ifaces']) ) {
        if ( (!exists(SELF['type']) || SELF['type'] != 'bond_ifaces') ) {
            error("bond_ifaces is defined but the type of interface is not defined as OVSBond");
        };
        foreach (i; iface; bond_ifaces) {
            if ( !exists("/system/network/interfaces/" + iface) ) {
                error("The " + iface + " interface is used by bond_ifaces, but does not exist");
            };
        };
    };
    if (exists(SELF['ip']) && exists(SELF['netmask'])) {
        if (exists(SELF['gateway']) && ! ip_in_network(SELF['gateway'], SELF['ip'], SELF['netmask'])) {
            error(format('networkinterface has gateway %s not reachable from ip %s with netmask %s',
                            SELF['gateway'], SELF['ip'], SELF['netmask']));
        };
        if (exists(SELF['broadcast']) && ! ip_in_network(SELF['broadcast'], SELF['ip'], SELF['netmask'])) {
            error(format('networkinterface has broadcast %s not reachable from ip %s with netmask %s',
                            SELF['broadcast'], SELF['ip'], SELF['netmask']));
        };
    };
    true;
};


@documentation{
    router
}
type structure_router = string[];

@documentation{
    IPv6 global settings
}
type structure_ipv6 = {
    "enabled" ? boolean
    "default_gateway" ? type_ip
    "gatewaydev" ? valid_interface # sets IPV6_DEFAULTDEV
};

@documentation{
    Host network configuration

    These values are used to generate /etc/sysconfig/network
    when using ncm-network (unless specified otherwise).
}
type structure_network = {
    "domainname" : type_fqdn
    "hostname" : type_shorthostname
    "realhostname" ? type_fqdn
    "default_gateway" ? type_ip
    @{When default_gateway is not set, the component will try to guess the default
      gateway using the first configured gateway set on an interface.
      The default is true for backward compatible behaviour.}
    "guess_default_gateway" ? boolean
    "gatewaydev" ? valid_interface
    @{Per interface network settings.
      These values are used to generate the /etc/sysconfig/network-scripts/ifcfg-<interface> files
      when using ncm-network.}
    "interfaces" : structure_interface{}
    "nameserver" ? type_ip[]
    "nisdomain" ? string(1..64) with match(SELF, '^\S+$')
    @{Setting nozeroconf to true stops an interface from being assigned an automatic address in the 169.254.0.0 subnet.}
    "nozeroconf" ? boolean
    @{The default behaviour for all interfaces wrt setting the MAC address (see interface set_hwaddr attribute).
      The component default is false.}
    "set_hwaddr" ? boolean
    "nmcontrolled" ? boolean
    "allow_nm" ? boolean
    "primary_ip" ? string
    "routers" ? structure_router{}
    "ipv6" ? structure_ipv6
} with {
    if (exists(SELF['default_gateway'])) {
        reachable = false;
        # is there any interface that can reach it?
        foreach (name; data; SELF['interfaces']) {
            if (exists(data['ip']) && exists(data['netmask']) &&
                ip_in_network(SELF['default_gateway'], data['ip'], data['netmask'])) {
                reachable = true;
            };
        };
        if (!reachable) {
            error("No interface with ip/mask found to reach default gateway");
        };
    };
    true;
};

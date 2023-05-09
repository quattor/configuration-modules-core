# This should be included from quattor/schema

declaration template components/network/core-schema;

include 'pan/types';
include 'quattor/functions/network';

type network_valid_routing_table = string with exists("/system/network/routing_table/" + SELF);

type network_ip_cmd_prefix = string with {is_ipv4_netmask_pair(SELF) || is_ipv6_network_block(SELF)};

@documentation{
    Add route (IPv4 of IPv6)
    Presence of ':' in any of the values indicates this is IPv6 related.
}
type structure_route = {
    @{The ADDRESS in ADDRESS/PREFIX via GATEWAY}
    "address" ? string with {SELF == 'default' || is_ip(SELF)}
    @{The PREFIX in ADDRESS/PREFIX via GATEWAY}
    "prefix"  ? long
    @{The GATEWAY in ADDRESS/PREFIX via GATEWAY}
    "gateway" ? type_ip
    @{alternative notation for prefix (cannot be combined with prefix)}
    "netmask" ? type_ip
    @{routing table}
    "table" ? network_valid_routing_table
    @{pretend that the nexthop is directly attached to this link}
    "onlink" ? boolean
    @{route add command options to use (cannot be combined with other options)}
    "command" ? string with !match(SELF, '[;]')
} with {
    if (exists(SELF['command'])) {
        if (length(SELF) != 1)
            error("Cannot use command and any of the other attributes as route");
    } else {
        if (!exists(SELF['address']))
            error("Address is mandatory for route (in absence of command)");
        if (exists(SELF['prefix']) && exists(SELF['netmask']))
            error("Use either prefix or netmask as route");
    };

    if (exists(SELF['prefix'])) {
        pref = SELF['prefix'];
        ipv6 = false;
        foreach (k; v; SELF) {
            if (match(to_string(v), ':')) {
                ipv6 = true;
            };
        };
        if (ipv6) {
            if (!is_ipv6_prefix_length(pref)) {
                error(format("Prefix %s is not a valid IPv6 prefix", pref));
            };
        } else {
            if (!is_ipv4_prefix_length(pref)) {
                error(format("Prefix %s is not a valid IPv4 prefix", pref));
            };
        };
    };

    true;
};

@documentation{
    Add rule (IPv4 of IPv6)
    Presence of ':' in any of the values indicates this is IPv6 related.
}
type structure_rule = {
    @{to selector}
    "to" ? network_ip_cmd_prefix
    @{from selector}
    "from" ? network_ip_cmd_prefix
    @{not action (false value means no not action; also the default when not is not defined)}
    "not" ? boolean
    @{routing table action}
    "table" ? network_valid_routing_table
    @{rule add options to use (cannot be combined with other options)}
    "command" ? string with !match(SELF, '[;]')
} with {
    if (exists(SELF['command'])) {
        if (length(SELF) != 1)
            error("Cannot use command and any of the other attributes as rule");
    } else {
        if (!exists(SELF['to']) && !exists(SELF['from'])) {
            error("Rule requires selector to or from (or use command)");
        };
        if (!exists(SELF['table'])) {
            error("Rule requires action table (or use command)");
        };
    };
    true;
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
    Set the number of channels.
    See ethtool --show-channels for the values.
}
type structure_ethtool_channels = {
    "rx" ? long(0..)
    "tx" ? long(0..)
    "other" ? long(0..)
    "combined" ? long(0..)
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
type structure_ethtool_wol = string with match (SELF, '^(p|u|m|b|a|g|s|d)+$');

@documentation{
    ethtool
}
type structure_ethtool = {
    "wol" ? structure_ethtool_wol
    "autoneg" ? string with match (SELF, '^(on|off)$')
    "duplex" ? string with match (SELF, '^(half|full)$')
    "speed" ? long
    "channels" ? structure_ethtool_channels
};

@documentation{
    interface plugin for vxlan support via initscripts-vxlan
}
type structure_interface_plugin_vxlan = {
    @{VXLAN Network Identifier (or VXLAN Segment ID); derived from devicename vxlan[0-9] if not defined}
    'vni' ? long(0..16777216)
    @{multicast ip to join}
    'group' ? type_ip
    @{destination IP address to use in outgoing packets}
    'remote' ? type_ip
    @{source IP address to use in outgoing packets}
    'local' ? type_ip
    @{UDP destination port}
    'dstport' ? long(2..65535)
    @{Group Policy extension}
    'gbp' ? boolean
} with {
    if (exists(SELF['group']) && exists(SELF['remote'])) {
        error('Cannot define both group and remote for vxlan');
    };
    if (!exists(SELF['group']) && !exists(SELF['remote'])) {
        error('Must define either group or remote for vxlan');
    };
    true;
};

@documentation{
    interface plugin via custom ifup/down[-pre]-local hooks
}
type structure_interface_plugin = {
    @{VXLAN support via initscripts-vxlan}
    "vxlan" ? structure_interface_plugin_vxlan
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
    "bootproto" ? string with match(SELF, '^(static|bootp|dhcp|none)$')
    "onboot" ? boolean
    "type" ? string with match(SELF, '^(Ethernet|Bridge|Tap|xDSL|IPIP|OVS(Bridge|Port|IntPort|Bond|Tunnel|PatchPort))$')
    "device" ? string
    "master" ? string
    "mtu" ? long
    @{Routes for this interface.
      These values are used to generate the /etc/sysconfig/network-scripts/route[6]-<interface> files
      as used by ifup-routes when using ncm-network.
      This allows for mixed IPv4 and IPv6 configuration}
    "route" ? structure_route[]
    @{Rules for this interface.
      These values are used to generate the /etc/sysconfig/network-scripts/rule[6]-<interface> files
      as used by ifup-routes when using ncm-network.
      This allows for mixed IPv4 and IPv6 configuration}
    "rule" ? structure_rule[]
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

    @{Is a VLAN device. If the device name starts with vlan, this is always true.}
    "vlan" ? boolean
    @{If the device name starts with vlan, this has to be set.
      It is set (but ignored by ifup) if it the device is not named vlan}
    "physdev" ? valid_interface

    "fqdn" ? string
    "network_environment" ? string
    "network_type" ? string
    "nmcontrolled" ? boolean
    @{Set DEFROUTE, is the default for ipv6_defroute}
    "defroute" ? boolean

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
    @{Set IPV6_DEFROUTE, defaults to defroute value}
    "ipv6_defroute" ? boolean
    "ipv6addr" ? type_network_name
    "ipv6addr_secondaries" ? type_network_name[]
    "ipv6init" ? boolean

    @{tunnel IP}
    "my_inner_ipaddr" ? type_ip
    @{tunnel IP netmask prefix}
    "my_inner_prefix" ? long(0..32)
    @{primary local IP address}
    "my_outer_ipaddr" ? type_ip
    @{remote peer primary IP address}
    "peer_outer_ipaddr" ? type_ip

    "plugin" ? structure_interface_plugin
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
        if ( (!exists(SELF['type']) || SELF['type'] != 'OVSBond') ) {
            error("bond_ifaces is defined but the type of interface is not defined as OVSBond");
        };
        foreach (i; iface; SELF['bond_ifaces']) {
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
    if (exists(SELF['plugin']) && exists(SELF['plugin']['vxlan']) && ! exists(SELF['physdev'])) {
        error('vxlan plugin requires physdev');
    };

    foreach (i; name; list('my_inner_ipaddr', 'my_inner_prefix', 'my_outer_ipaddr', 'peer_outer_ipaddr')) {
        if ( exists(SELF[name]) && (!exists(SELF['type']) || SELF['type'] != 'IPIP')) {
            error("%s is defined but the type of interface is not defined as IPIP", name);
        };
    };

    if ( exists(SELF['type']) && SELF['type'] == 'IPIP' ) {
        foreach (i; name; list('my_inner_ipaddr', 'my_inner_prefix', 'my_outer_ipaddr')) {
            if (!exists(SELF[name])) {
                error("Type IPIP but %s is not defined.", name);
            };
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
    "nm_manage_dns" ? boolean
    "primary_ip" ? string
    "routers" ? structure_router{}
    "ipv6" ? structure_ipv6
    @{Manage custom routing table entries; key is the name; value is the id}
    "routing_table" ? long(1..252){} with {
        if (exists(SELF['main']) || exists(SELF['local']) || exists(SELF['default']) || exists(SELF['unspec'])) {
            error("No reserved names in routing table");
        };
        true;
    }
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

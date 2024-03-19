declaration template components/network/types/network/tunnel;

@documentation{
    interface plugin for vxlan support via initscripts-vxlan
}
type network_interface_plugin_vxlan = {
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

# moved here, because this probably no nmstate equivalent to plugins
#   vxlan doesn't need one in any case
@documentation{
    interface plugin via custom ifup/down[-pre]-local hooks
}
type network_interface_plugin = {
    @{VXLAN support via initscripts-vxlan}
    "vxlan" ? network_interface_plugin_vxlan
};


type network_interface_tunnel = {
    @{tunnel IP}
    "my_inner_ipaddr" ? type_ip
    @{tunnel IP netmask prefix}
    "my_inner_prefix" ? long(0..32)
    @{primary local IP address}
    "my_outer_ipaddr" ? type_ip
    @{remote peer primary IP address}
    "peer_outer_ipaddr" ? type_ip

    "plugin" ? network_interface_plugin
};


@{validate the network_interface tunnel config. error on error}
function network_interface_tunnel_validate = {
    nwcfg = ARGV[0];
    if (exists(nwcfg['plugin']) && exists(nwcfg['plugin']['vxlan']) && ! exists(nwcfg['physdev'])) {
        error('vxlan plugin requires physdev');
    };

    foreach (i; name; list('my_inner_ipaddr', 'my_inner_prefix', 'my_outer_ipaddr', 'peer_outer_ipaddr')) {
        if ( exists(nwcfg[name]) && (!exists(nwcfg['type']) || nwcfg['type'] != 'IPIP')) {
            error("%s is defined but the type of interface is not defined as IPIP", name);
        };
    };

    if ( exists(nwcfg['type']) && nwcfg['type'] == 'IPIP' ) {
        foreach (i; name; list('my_inner_ipaddr', 'my_inner_prefix', 'my_outer_ipaddr')) {
            if (!exists(nwcfg[name])) {
                error("Type IPIP but %s is not defined.", name);
            };
        };
    };
    true;
};

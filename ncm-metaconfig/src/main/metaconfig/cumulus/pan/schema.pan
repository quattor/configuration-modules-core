declaration template metaconfig/cumulus/schema;

include 'pan/types';
include 'quattor/functions/network';

type cumulus_port = string;

# 169.254.0.1 is reserved by cumulus for BGP
type cumulus_ipv4 = type_ipv4 with SELF != '169.254.0.1';

type cumulus_vlan = long(1..4095);

@{in 1000}
type cumulus_port_speed = long with index(SELF, list(1, 10, 25, 40, 50, 100)) > -1;

type cumulus_interface_bridge = {
    @{access port to VLAN}
    'access' ? cumulus_vlan
    @{tagger VLANs, VLAN for untagged traffic is bridge pvid}
    'vids' ? cumulus_vlan[]
    @{interface is part of bridge (default called bridge)}
    'enable' : boolean = true
} = dict();

type cumulus_interface_bridge_common = {
    @{comment field}
    'alias' ? string
    @{clag ip address}
    'address' ? cumulus_ipv4
    @{address subnet prefix}
    'mask' ? long(0..32) # naming follows cumulus configuration, but it is a prefix
    @{VRF (mgmt is reserved for the managment interface only)}
    'vrf' ? string with length(SELF) < 15
};

type cumulus_interface_common = {
    include cumulus_interface_bridge_common
    'bridge' : cumulus_interface_bridge
};

type cumulus_clagd = {
    'peer-ip' : cumulus_ipv4
    @{MAC should be the same for both MLAG members}
    'sys-mac' :  type_hwaddr with match(SELF, '^44:38:39:[fF][fF]:') # reserved cumulus range
    'backup-ip' ? cumulus_ipv4
    'priority' ? long(0..65535)
};

type cumulus_peerlink = {
    include cumulus_interface_common
    @{bond slaves for the link}
    'slaves' : cumulus_port[] with length(SELF) >= 1 && length(SELF) <= 2
    @{vlan dedicated to the peerlink}
    'vlan' : cumulus_vlan = 4094
    'clagd' : cumulus_clagd
} with {
    # clagd peer-ip must be reachable via address/mask
    if (!ip_in_network(SELF['clagd']['peer-ip'], SELF['address'], subnet_prefix_to_mask(SELF['mask']))) {
        error("clagd peer-ip %s not in network %s/%s", SELF['clagd']['peer-ip'], SELF['address'], SELF['mask']);
    };
    true;
};

type cumulus_interface_link = {
    'autoneg' ? boolean
    @{in 1000}
    'speed' ? cumulus_port_speed
};

type cumulus_interface = {
    include cumulus_interface_common
    'inet' ? choice('loopback', 'dhcp')
    'gateway' ? type_ipv4
    @{bond slaves for the link}
    'slaves' ? cumulus_port[]
    @{command to run after interface is up}
    'post-up' ? string
    @{mandatory and unique for dual-connected hosts, using ports on different MLAG members}
    'clag-id' ? long(0..65535)
    'link' ? cumulus_interface_link
    @{LACP bypass (eg to PXE hosts with LACP)}
    'bond-lacp-bypass-allow' ? boolean
    @{STP BPDU Guard}
    'mstpctl-bpduguard' ? boolean
} with {
    if (exists(SELF['gateway'])) {
        if (!ip_in_network(SELF['gateway'], SELF['address'], subnet_prefix_to_mask(SELF['mask']))) {
            error("interface gateway %s not in network %s/%s", SELF['gateway'], SELF['address'], SELF['mask']);
        };
    };
    true;
};

type cumulus_bridge_common = {
    @{STP}
    'stp' ? boolean
    @{VLAN aware}
    'vlan-aware' ? boolean
};

type cumulus_bridge = {
    include cumulus_bridge_common
    @{VLAN for untagged packets}
    'pvid' ? cumulus_vlan
    @{Supported VLANs}
    'vids' ? cumulus_vlan[]
    @{enable/disable multicast snooping}
    'mcsnoop' ? boolean
};

type cumulus_bridge_traditional = {
    include cumulus_bridge_common
    include cumulus_interface_bridge_common
    @{interfaces that are part of this bridge}
    'ports' : string[] with {
        interfaces = dict();
        foreach (idx; inf; SELF) {
            intf = replace('\.*$', '', inf);
            if (exists(interfaces[intf])) {
                error("Cannot have 2 subinterfaces in ports: %s found %s", intf, interfaces);
            } else {
                interfaces[intf] = true;
            };
        };
        true;
    }
    @{VLAN id, when defined, will be added to interfaces that do not have a vlan tag}
    'vid' ? cumulus_vlan
};

type cumulus_interfaces = {
    @{interfaces}
    'interfaces' ? cumulus_interface{}
    @{MLAG peerlink configuration}
    'peerlink' ? cumulus_peerlink
    @{single bridge, reserved name for vlan-aware bridge. use 'bridges' for traditional bridges}
    'bridge' ? cumulus_bridge
    @{traditional bridge(s). key makes interface "br-<key>"}
    'bridges' ? cumulus_bridge_traditional{}
} with {
    # peerlink vlan is unique for the peerlink
    peervlan = -1;
    if (exists(SELF['peerlink'])) {
        peervlan = SELF['peerlink']['vlan'];
    };
    # clag-id is unique
    clagids = list();
    if (exists(SELF['interfaces'])) {
        foreach (name; inf; SELF['interfaces']) {
            if (length(name) > 15) {
                error("Interface name %s is more then 15 chars", name);
            };
            if (exists(inf['clag-id'])) {
                if (index(inf['clag-id'], clagids) >= 0) {
                    error('clag-id %s found twice (last for interface %s)', inf['clag-id'], name);
                } else {
                    clagids = append(clagids, inf['clag-id']);
                };
            };
            if (exists(inf['bridge']['vids'])) {
                foreach (idx; vid; inf['bridge']['vids']) {
                    if (peervlan == vid) {
                        error("Interface %s has peerlink VLAN configured", name);
                    };
                };
            };
        };
    };
    # bridge PVID in VIDS
    if (exists(SELF['bridge'])) {
        br = SELF['bridge'];
        if (exists(br['pvid']) && exists(br['vids']) &&
            index(br['pvid'], br['vids']) < 0) {
            error("Bridge PVID %s must be part of the bridge vids %s", br['pvid'], br['vids']);
        };
    };
    # traditional bridges
    if (exists(SELF['bridges'])) {
        ports = dict();
        foreach (brname; br; SELF['bridges']) {
            if (length(brname) > 12) {
                error("Traditional bridge name %s is more then 12 chars (without br- prefix)", brname);
            };
            foreach (idx; port; br['ports']) {
                if (exists(br['vid']) && !match('\.\d+$', port)) {
                    port = format("%s.%s", port, br['vid']);
                };
                if (exists(ports[port])) {
                    error("ports can only be in one bridge: found %s in %s, also in %s", port, brname, ports[port]);
                } else {
                    ports[port] = brname;
                };
            };
        };
    };
    true;
};

@{a port in a switch. default setting is a disabled port.}
type cumulus_ports_port = {
    'speed' : cumulus_port_speed = 1
    @{number of ports. 0 is disabled port, -1 is short for number:1,speed:default}
    'number' : long(-1..) = -1
} = dict();

type cumulus_ports = {
    @{port numbers are increased with 1 relative to the index in the list}
    'ports' : cumulus_ports_port[]
    @{default port speed}
    'default' : cumulus_port_speed
};

type cumulus_frr_route = {
    @{network}
    'network' : type_ipv4
    @{network mask}
    'mask' : long(0..32)
    @{nethop ip or blackhole null0}
    'nexthop' : string with is_ipv4(SELF) || SELF == 'null0'
};

@{Simple/minimal FRRouting config file, useful for static routing in VRF setup}
type cumulus_frr = {
    @{Routes per VRF (key is VRF name)}
    'vrf' : cumulus_frr_route[]{}
};

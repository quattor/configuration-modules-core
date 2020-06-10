declaration template metaconfig/dellnetworking/schema;

include 'pan/types';
include 'quattor/functions/network';

# see TODO below why this is split in a function
function is_dellnetworking_interface_name = {
    match(ARGV[0],
        '^((ethernet)\s?(\d+/\d+/\d+(:\d+)?))|((port-channel|vlan)\s?\d+)$');
};

type dellnetworking_interface_name = string with is_dellnetworking_interface_name(SELF);

# 4094 is reserved for VLT
type dellnetworking_vlan = long(1..4093);

type dellnetworking_vlt = {
    @{VLT domain id, should be the same for both VLT members, globally unique}
    'id' : long(0..)
    @{vlt-mac, should be the same for both VLT members, globally unique}
    'mac' ?  type_hwaddr with match(SELF, '^44:38:39:[fF][fF]:') # reserved dellnetworking range, same as cumulus
    @{discovery interfaces}
    'discovery' : dellnetworking_interface_name[] with length(SELF) >= 1
    @{backup ip}
    'backup' ? type_ipv4
    @{delay restore timeout}
    'delay' ? long
    @{primary priority (default 32k, higher number means lower priority}
    'priority' ? long(0..65535)
    @{mtu}
    'mtu' ? long(1280..65535)
    @{enable/disable peer routing}
    'peerrouting' ? boolean
};

type dellnetworking_lacp = {
    @{LACP mode}
    'mode' ? choice('active', 'passive')
    @{LACP fallback (eg to PXE hosts with LACP)}
    'fallback' ? boolean
    @{LACP fallback timeout}
    'timeout' ? long(0..120)
    @{LACP fast rate}
    'fast' ? boolean
    @{LACP priority (default 32k, higher number means lower priority}
    'priority' ? long(0..65535)
};

type dellnetworking_ip = {
    @{ip address}
    'ip' ? type_ipv4
    @{address subnet mask}
    'mask' ? long(0..32)
};

type dellnetworking_interface = {
    include dellnetworking_ip
    @{interface is enabled}
    'enable' : boolean = true
    @{description field}
    'description' ? string
    @{access port to VLAN (implies trunk mode; no access VLAN defined implies access mode)}
    'access' ? dellnetworking_vlan
    @{tagged VLANs, VLAN for untagged traffic is bridge pvid}
    'vids' ? dellnetworking_vlan[]
    @{bond slaves for the link, required for port channels}
    'slaves' ? dellnetworking_interface_name[] with length(SELF) >= 1
    @{mandatory and unique for dual-connected hosts, using ports on different VLT members}
    'vlt' ? long(0..65535)
    @{lacp}
    'lacp' ? dellnetworking_lacp
    @{force speed}
    'speed' ? long with index(SELF, list(10000, 25000, 40000, 50000, 100000)) >= 0
    @{mtu}
    'mtu' ? long(1280..65535)
    @{enable/disable spanning-tree edge port}
    'edge' ? boolean
    @{set to true to suppress any switchport statement being generated; set to false to disable it}
    'switchport' ? boolean
} with {
    if (exists(SELF['slaves'])) {
        if (!(exists(SELF['lacp']) && exists(SELF['lacp']['mode']))) {
            error("port-channel must define lacp mode");
        };
    } else {
        foreach (idx; key; list('vlt')) {
            if (exists(SELF[key])) {
                error("%s cannot be set without slaves defined", key)
            };
        };
        if (exists(SELF['lacp'])) {
            foreach (idx; key; list('fallback', 'mode', 'priority')) {
                if (exists(SELF['lacp'][key])) {
                    error("lacp %s cannot be set without slaves defined", key)
                };
            };
        };
    };
    if (exists(SELF['access']) &&
        exists(SELF['vids']) &&
        index(SELF['access'], SELF['vids']) >= 0) {
            error("access vlan %s cannot be part of trunk allowed vlan ids %s", SELF['access'], SELF['vids']);
    };
    true;
};

type dellnetworking_user = {
    @{password hash}
    'password' : string
    @{role}
    'role' : choice('sysadmin')
    @{one pubkey}
    'pubkey' ? string
};

type dellnetworking_management = {
    include dellnetworking_ip
    'gateway' : type_ipv4
    'ipv6' : boolean = false
};

@{key is feature name, value is boolean (false will disable the feature)}
type dellnetworking_feature = {
    'auto-breakout' ? boolean
};

type dellnetworking_logserver = {
    "ip" : type_ipv4
    "level" ? choice("emerg", "alert", "crit", "err", "warning", "notice", "info", "debug")
    "transport" ? choice("tcp", "udp", "tls")
    "port" ? long(1..65535)
};

@{the ip/mask define the subnet}
type dellnetworking_route = {
    @{subnet}
    'subnet' : type_ipv4
    @{subnet mask}
    'mask' : long(0..32)
    @{gateway}
    'gateway' : type_ipv4
};

type dellnetworking_config = {
    @{features}
    'feature' ? dellnetworking_feature
    @{name servers to use}
    'nameserver' ? type_hostname[1..3]
    @{hostname}
    'hostname' : type_hostname
    @{ntp server}
    'ntp' ? type_hostname
    @{system user linuxadmin password hash}
    'systemuser' : string
    @{users, key is the username}
    'users' : dellnetworking_user{}
    @{port groups}
    'portgroups' ? choice('10g-4x', '25g-4x', '40g-1x', '50g-2x', '100g-1x', '100g-2x'){}
    @{Default PVID for untagged traffic}
    'pvid' : dellnetworking_vlan
    @{VLAN IDs (simple enabled VLANs)}
    'vlanids' ? dellnetworking_vlan[]
    @{management interface}
    'management' : dellnetworking_management
    @{interfaces}
    'interfaces' : dellnetworking_interface{}
    @{VLT configuration}
    'vlt' ? dellnetworking_vlt
    @{logserver configuration}
    'logserver' ? dellnetworking_logserver
    @{static routes}
    'routes' ? dellnetworking_route[]
} with {
    # VLT discovery interfaces cannot be interfaces
    if (exists(SELF['vlt'])) {
        foreach (idx; name; SELF['vlt']['discovery']) {
            if (exists(SELF['interfaces'][escape(name)])) {
                error("discovery interface %s cannot be configured as interface", name);
            };
        };
    };

    # track all known vlan ids
    if (exists(SELF['vlanids'])) {
        knownvids = append(clone(SELF['vlanids']), SELF['pvid']);
    } else {
        knownvids = list(SELF['pvid']);
    };

    foreach (esname; inf; SELF['interfaces']) {
        vlan = matches(unescape(esname), '^vlan\s*(\d+)$');
        if (length(vlan) == 2) {
            vid = to_long(vlan[1]);
            if (index(vid, knownvids) < 0) {
                append(knownvids, vid);
            } else {
                error("interface vlan %s is already known", vid);
            };
        };
    };

    # vlt port channel ids and slave interfaces are unique
    vltpcids = list();
    slifs = list();

    foreach (esname; inf; SELF['interfaces']) {
        name = unescape(esname);
        # all interfaces must match the dellnetworking_interface_name type
        # TODO: when using
        #        if (! is_valid(dellnetworking_interface_name, name)) {
        #   we get a compiler error
        if (!is_dellnetworking_interface_name(name)) {
            error("require valid interface name, got %s", name);
        };

        if (exists(inf['access'])) {
            if (index(inf['access'], knownvids) < 0) {
                error("access vlan %s for %s is unknown vlan", inf['access'], name);
            };
        };
        if (exists(inf['vids'])) {
            foreach (idx; vid; inf['vids']) {
                if (index(vid, knownvids) < 0) {
                    error("allowed trunk vlan %s for %s is unknown vlan", vid, name);
                };
            };
        };

        if (exists(inf['slaves'])) {
            m = matches(name, '^port-channel\s*(\d+)$');
            if (length(m) == 2) {
                pcid = to_long(m[1]);
                if (pcid < 1 || pcid > 128) {
                    error("port-channel id must be between 1 and 128, got %s", name);
                };
            } else {
                error("only port-channels can have slaves defined, found %s", name);
            };
            foreach (idx; slname; inf['slaves']) {
                if (exists(SELF['interfaces'][escape(slname)])) {
                    error("slave interface %s (for interface %s) cannot be configured as interface",
                            slname, name);
                };
                if (index(slname, slifs) >= 0) {
                    error('slave interface %s found twice (last for interface %s)', slname, name);
                } else {
                    slifs = append(slifs, slname);
                };
            };
        };
        if (!exists(inf['slaves']) && match(name, '^port-channel')) {
            error("port-channel must have slaves defined, found %s", name);
        };
        if (exists(inf['vlt'])) {
            if (index(inf['vlt'], vltpcids) >= 0) {
                error('vlt port channel id %s found twice (last for interface %s)', inf['vlt'], name);
            } else {
                vltpcids = append(vltpcids, inf['vlt']);
            };
        };
    };
    true;
};

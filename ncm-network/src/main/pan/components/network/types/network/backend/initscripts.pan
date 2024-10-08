declaration template components/network/types/network/backend/initscripts;

@{implement types specific for initscripts / network.pm}

include 'components/network/types/network/route';

type structure_network_backend_specific = {
};

@documentation{
    Add route (IPv4 of IPv6)
    Presence of ':' in any of the values indicates this is IPv6 related.
}
type network_route = {
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
        if (length(SELF) != 1) error("Cannot use command and any of the other attributes as route");
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
                error("Prefix %s is not a valid IPv6 prefix", pref);
            };
        } else {
            if (!is_ipv4_prefix_length(pref)) {
                error("Prefix %s is not a valid IPv4 prefix", pref);
            };
        };
    };

    true;
};

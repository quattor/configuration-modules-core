declaration template components/network/types/network/route;

type network_valid_routing_table = string with exists("/system/network/routing_table/" + SELF);

function network_valid_prefix = {
    pref = ARGV[0]['prefix'];
    ipv6 = false;
    foreach (k; v; ARGV[0]) {
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
    @{congestion window size}
    "cwnd" ? long(10..)
    @{Initial congestion window size, applied to all sockets for the given targets.}
    "initcwnd" ? long(10..)
    @{Advertised receive window, applied to all sockets for the given targets.}
    "initrwnd" ? long(10..)
    @{route add command options to use (cannot be combined with other options)}
    "command" ? string with !match(SELF, '[;]')
} with network_valid_route(SELF);

declaration template components/network/types/network/rule;

type network_ip_cmd_prefix = string with {is_ipv4_netmask_pair(SELF) || is_ipv6_network_block(SELF)};

@documentation{
    Add rule (IPv4 of IPv6)
    Presence of ':' in any of the values indicates this is IPv6 related.
}
type network_rule = {
    include structure_network_rule_backend_specific
    @{to selector}
    "to" ? network_ip_cmd_prefix
    @{from selector}
    "from" ? network_ip_cmd_prefix
    @{not action (false value means no not action; also the default when not is not defined)}
    "not" ? boolean
    @{routing table action}
    "table" ? network_valid_routing_table
    @{priority, The priority of the rule over the others. Required by Network Manager when setting routing rules.}
    "priority" ? long(0..0xffffffff)
    @{rule add options to use (cannot be combined with other options)}
    "command" ? string with !match(SELF, '[;]')
} with network_valid_rule(SELF);

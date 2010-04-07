# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/iptables/schema;

include { "quattor/schema" };

type component_iptables_rule = {
    "new_chain"          ? string
    "append"             ? string
    "delete"             ? string
    "insert"             ? string
    "replace"            ? string
    "target"             ? string
    "jump"               ? string
    "src_addr"           ? string
    "src"                ? string
    "source"             ? string
    "src_port"           ? string
    "src_ports"          ? string
    "dst_addr"           ? string
    "dst"                ? string
    "destination"        ? string
    "dst_port"           ? string
    "dst_ports"          ? string
    "in_interface"       ? string
    "in-interface"       ? string
    "out_interface"      ? string
    "out-interface"      ? string
    "match"              ? string
    "state"              ? string
    "ctstate"            ? string
    "ttl"                ? string
    "tos"                ? string
    "sid-owner"          ? string
    "limit"              ? string
    "syn"                ? boolean
    "nosyn"              ? boolean
    "icmp-type"          ? string
    "protocol"           ? string
    "log-prefix"         ? string
    "log-level"          ? string
    "log-tcp-options"    ? boolean
    "log-tcp-sequence"   ? boolean
    "log-ip-options"     ? boolean
    "log-uid"            ? boolean
    "reject-with"        ? string
    "set-class"          ? string
    "limit-burst"        ? string
    "to-destination"     ? string
    "to-ports"           ? string
    "uid-owner"          ? string
    "tcp-flags"          ? string
    "tcp-option"         ? string
    "command"           ? string
    "chain"             : string
    "icmp_type"         ? string
    "fragment"          ? boolean
    "nofragment"        ? boolean
    "length"            ? string
    "set"               ? boolean
    "rcheck"            ? boolean
    "seconds"           ? number
    "pkt-type"          ? string   

};

type component_iptables_preamble = {
    "input"             ? string
    "output"            ? string
    "forward"           ? string
    "prerouting"        ? string
    "postrouting"       ? string
};

type component_iptables_acls = {
    "preamble"          ? component_iptables_preamble
    "rules"             ? component_iptables_rule[]
    "epilogue"          ? string
    "ordered_rules"     ? string with match (SELF, 'yes|no')
};

type component_iptables = {
    include structure_component
    "filter"            ? component_iptables_acls
    "nat"               ? component_iptables_acls
    "mangle"            ? component_iptables_acls
};

bind "/software/components/iptables" = component_iptables;

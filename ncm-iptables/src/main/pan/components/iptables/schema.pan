# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/iptables/schema;

include "quattor/schema";

type component_iptables_rule = {
    "new_chain" ? string
    "append" ? string
    "delete" ? string
    "insert" ? string
    "replace" ? string
    "target" ? string with {deprecated(0, 'Duplicate parameter target is deprecated, use jump instead'); true;}
    "jump" ? string
    "src_addr" ? string with {deprecated(0, 'Duplicate parameter src_addr is deprecated, use source instead'); true;}
    "src" ? string with {deprecated(0, 'Duplicate parameter src is deprecated, use source instead'); true;}
    "source" ? string
    "src_port" ? string
    "src_ports" ? string
    "dst_addr" ? string with {deprecated(0, 'Duplicate parameter dst_addr is deprecated, use destination instead'); true;}
    "dst" ? string with {deprecated(0, 'Duplicate parameter dst is deprecated, use destination instead'); true;}
    "destination" ? string
    "dst_port" ? string
    "dst_ports" ? string
    "in_interface" ? string with {deprecated(0, 'Duplicate parameter in_interface is deprecated, use in-interface instead'); true;}
    "in-interface" ? string
    "out_interface" ? string with {deprecated(0, 'Duplicate parameter out_interface is deprecated, use out-interface instead'); true;}
    "out-interface" ? string
    "match" ? string
    "state" ? string
    "ctstate" ? string
    "ttl" ? string
    "tos" ? string
    "sid-owner" ? string
    "limit" ? string
    "syn" ? boolean
    "nosyn" ? boolean
    "icmp-type" ? string
    "protocol" ? string
    "log-prefix" ? string
    "log-level" ? string
    "log-tcp-options" ? boolean
    "log-tcp-sequence" ? boolean
    "log-ip-options" ? boolean
    "log-uid" ? boolean
    "reject-with" ? string
    "set-class" ? string
    "limit-burst" ? string
    "to-destination" ? string
    "to-ports" ? string
    "to-source" ? string
    "uid-owner" ? string
    "tcp-flags" ? string
    "tcp-option" ? string
    "command" ? string
    "chain" : string
    "icmp_type" ? string
    "fragment" ? boolean
    "nofragment" ? boolean
    "length" ? string
    "set" ? boolean
    "rcheck" ? boolean
    "remove" ? boolean
    "rdest" ? boolean
    "rsource" ? boolean
    "rttl" ? boolean
    "update" ? boolean
    "seconds" ? number
    "hitcount" ? number
    "name" ? string
    "pkt-type" ? string
    "comment" ? string with match(SELF, '^(?=\S).{1,256}(?<=\S)$')
};

type component_iptables_preamble = {
    "input" ? string
    "output" ? string
    "forward" ? string
    "prerouting" ? string
    "postrouting" ? string
};

type component_iptables_acls = {
    "preamble" ? component_iptables_preamble
    "rules" ? component_iptables_rule[]
    "epilogue" ? string
    "ordered_rules" ? legacy_binary_affirmation_string
};

type component_iptables = {
    include structure_component
    "filter" ? component_iptables_acls
    "nat" ? component_iptables_acls
    "mangle" ? component_iptables_acls
};

bind "/software/components/iptables" = component_iptables;

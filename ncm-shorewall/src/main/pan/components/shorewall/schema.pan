# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/shorewall/schema;

include 'quattor/types/component';


# Keep this list in sync with list from TT file
@{a masq entry: dest source address proto port ipsec mark user switch origdest probability}
type component_shorewall_masq = {
    "dest" ? string[]
    "source" ? string
    "address" ? string[]
    "proto" ? string
    "port" ? string[]
    "ipsec" ? string[]
    "mark" ? string
    "user" ? string
    "switch" ? string
    "origdest" ? string
    "probability" ? double(0..1)
};

# Keep this list in sync with list from TT file
@{a tcinterfaces entry: interface type inbw outbw}
type component_shorewall_tcinterfaces = {
    "interface" : string
    "type" ? string with match(SELF, '^(in|ex)ternal$')
    "inbw" ? string
    "outbw" ? string
};

# Keep this list in sync with list from TT file
@{a tcpri entry: band proto port address interface helper}
type component_shorewall_tcpri = {
    "band" : long(1..3)
    "proto" ? string[]
    "port" ? long[]
    "address" ? string
    "interface" ? string
    "helper" ? string
};

# Keep this list in sync with list from TT file
@{a zones entry: zone[:parent] type options inoptions outoptions}
type component_shorewall_zones = {
    "zone" : string(1..5)
    "parent" ? string[]
    "type" ? string with match(SELF, '(ipv4|ipsec|firewall|bport|vserver|loopback|local)')
    "options" ? string[]
    "inoptions" ? string[]
    "outoptions" ? string[]
};

# Keep this list in sync with list from TT file
@{an interfaces entry: zone interface[:port] broadcast options}
type component_shorewall_interfaces = {
    "zone" : string
    "interface" : string
    "port" ? long(0..)
    "broadcast" ? string[]
    'options' ? string[]
};

# Keep this list in sync with list from TT file
@{a policy entry: src dst policy loglevel burst[:limit] connlimit}
type component_shorewall_policy = {
    "src" : string
    "dst" : string
    "policy" : string
    "loglevel" ? string
    "burst" ? string
    "limit" ? string
    "connlimit" ? string
};


# Keep this list in sync with list from TT file
@{a stoppedrules entry: action src dst proto dport sport}
type component_shorewall_stoppedrules = {
    "action" ? string with match(SELF, '^(ACCEPT|NOTRACK|DROP)$')
    "src" ? string[]
    "dst" ? string[]
    "proto" ? string[]
    "dport" ? long(0..)[]
    "sport" ? long(0..)[]
};

# Keep this list in sync with list from TT file
@{a rules src or dst entry: zone[:interface][:address] (default: all zones)}
type component_shorewall_rules_srcdst = {
    @{zone entry, all[+-]/any, the firewall itself ($FW) or none}
    "zone" : string = 'all'
    "interface" ? string
    @{address is an (mac)addres/range combo, e.g. ~00-A0-C9-15-39-78,155.186.235.0/24!155.186.235.16/28}
    "address" ? string[]
} = dict();

# Keep this list in sync with list from TT file
@{a rules entry: action src dst proto dstport srcport origdst rate user[:group] mark connlimit time headers switch helper}
type component_shorewall_rules = {
    "action" : string
    "src" : component_shorewall_rules_srcdst
    "dst" : component_shorewall_rules_srcdst
    "proto" ? string
    "dstport" ? string[]
    "srcport" ? string[]
    "origdst" ? string[]
    "rate" ? string[]
    "user" ? string
    "group" ? string
    "mark" ? string
    "connlimit" ? string
    "time" ? string
    "headers" ? string
    "switch" ? string
    "helper" ? string
};

type component_shorewall_shorewall_blacklist = string with
    match(SELF, '^(ALL|NEW|ESTABLISHED|RELATED|INVALID|UNTRACKED)$');

@{shorewall.conf options. only configured options are written to the configfile}
type component_shorewall_shorewall = {
    "accept_default" ? string
    "accounting" ? boolean
    "accounting_table" ? string with match(SELF, '^(filter|mangle)$')
    "add_ip_aliases" ? boolean
    "add_snat_aliases" ? boolean
    "adminisabsentminded" ? boolean
    "arptables" ? string
    "auto_comment" ? boolean with {deprecated(0, 'shorewall auto_comment deprecated by autocomment'); true;}
    "autocomment" ? boolean
    "autohelpers" ? boolean
    "automake" ? boolean
    "basic_filters" ? boolean
    "blacklist" ? component_shorewall_shorewall_blacklist[]
    "blacklist_disposition" ? string with match(SELF, '^((A_)?(DROP|REJECT))$')
    "blacklist_loglevel" ? string
    "blacklistnewonly" ? boolean with {deprecated(0, 'shorewall blacklistnewonly deprecated by blacklist'); true;}
    "chain_scripts" ? boolean
    "clampmss" ? boolean
    "clear_tc" ? boolean
    "complete" ? boolean
    "config_path" ? string
    "defer_dns_resolution" ? boolean
    "delete_then_add" ? boolean
    "detect_dnat_ipaddrs" ? boolean
    "disable_ipv6" ? boolean
    "dont_load" ? string[]
    "drop_default" ? string
    "dynamic_blacklist" ? boolean
    "dynamic_zones" ? boolean
    "expand_policies" ? boolean
    "exportmodules" ? boolean
    "exportparams" ? boolean
    "fastaccept" ? boolean
    "forward_clear_mark" ? boolean
    "geoipdir" ? string
    "helpers" ? string[]
    "high_route_marks" ? boolean
    "ignoreunknownvariables" ? boolean
    "implicit_continue" ? boolean
    "inline_matches" ? boolean
    "invalid_disposition" ? string with match(SELF, '^((A_)?(DROP|REJECT)|CONTINUE)$')
    "invalid_log_level" ? string
    "ip" ? string
    "ip_forwarding" ? string with match(SELF, "(On|Off|Keep)")
    "ipsecfile" ? string with match(SELF, '^zones$')
    "ipset" ? string
    "ipset_warnings" ? boolean
    "iptables" ? string
    "keep_rt_tables" ? boolean
    "legacy_faststart" ? boolean
    "load_helpers_only" ? boolean
    "lockfile" ? string
    "log_backend" ? string with match(SELF, '^(U?LOG|netlink)$')
    "logallnew" ? string
    "logfile" ? string
    "logformat" ? string
    "loglimit" ? string
    "log_martians" ? string with match(SELF, '^(Yes|No|Keep)$')
    "logtagonly" ? boolean
    "log_verbosity" ? string
    "maclist_disposition" ? string with match(SELF, '^((A_)?(DROP|REJECT)|ACCEPT)$')
    "maclist_log_level" ? string
    "maclist_table" ? string with match(SELF, '^(filter|mangle)$')
    "maclist_ttl" ? long(0..)
    "mask_bits" ? long(0..)
    "mangle_enabled" ? boolean
    "mapoldactions" ? boolean
    "mark_in_forward_chain" ? boolean
    "modulesdir" ? string
    "module_suffix" ? string
    "multicast" ? boolean
    "mutex_timeout" ? long(0..)
    "nfqueue_default" ? string
    "null_route_rfc1918" ? boolean
    "optimize_accounting" ? boolean
    "optimize" ? string
    "path" ? string
    "perl" ? string
    "pkttype" ? boolean
    "queue_default" ? string
    "rcp_command" ? string
    "reject_default" ? string
    "require_interface" ? boolean
    "restore_default_route" ? boolean
    "restorefile" ? string
    "retain_aliases" ? boolean
    "route_filter" ? string with match(SELF, '^(Yes|No|Keep)$')
    "rsh_command" ? string
    "save_ipsets" ? boolean
    "shorewall_shell" ? string
    "smurf_log_level" ? string
    "startup_enabled" : boolean = true
    "startup_log" ? string
    "subsyslock" ? string
    "tc_bits" ? long(0..)
    "tc_enabled" ? string with match(SELF, '^(Yes|No|Internal|Simple|Shared)$')
    "tc_expert" ? boolean
    "tcp_flags_disposition" ? string
    "tcp_flags_log_level" ? string
    "tc_priomap" ? string
    "tc" ? string
    "track_providers" ? boolean
    "track_rules" ? boolean
    "use_default_rt" ? boolean
    "use_physical_names" ? boolean
    "use_rt_names" ? boolean
    "verbosity" ? long(0..2)
    "wide_tc_marks" ? boolean
    "workarounds" ? boolean
    "zone2zone" ? string
};

type component_shorewall = {
    include structure_component
    @{shorewall.conf configuration}
    "shorewall" ? component_shorewall_shorewall
    @{zones configuration}
    "zones" ? component_shorewall_zones[]
    @{interfaces configuration}
    "interfaces" ? component_shorewall_interfaces[]
    @{ configuration}
    "policy" ? component_shorewall_policy[]
    @{rules configuration}
    "rules" ? component_shorewall_rules[]
    @{tcinterfaces configuration}
    "tcinterfaces" ? component_shorewall_tcinterfaces[]
    @{tcpri configuration}
    "tcpri" ? component_shorewall_tcpri[]
    @{masq configuration}
    "masq" ? component_shorewall_masq[]
    @{rules to use when shorewall is stopped}
    "stoppedrules" ? component_shorewall_stoppedrules[]
};

@{metaconfig schema for shorewall 5.x sysconfig (you cannot set RESTARTOPTIONS)}
type shorewall_sysconfig = {
    'OPTIONS' ? string
    'STARTOPTIONS' : string = "/etc/shorewall"
    'RELOADOPTIONS' : string = "/etc/shorewall"
    'STOPOPTIONS' ? string
} = dict();

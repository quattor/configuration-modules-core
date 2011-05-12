# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/shorewall/schema;

include { 'quattor/schema' };

type component_shorewall_zones_zone = string;
type component_shorewall_zones_option = string with match(SELF,'');

type component_shorewall_zones = {
    "zone" : string
    "parent" ? component_shorewall_zones_zone[] 
    "type" : string with match(SELF, '(ipv4|ipsec|firewall|bport|-)')
    "options" ? component_shorewall_zones_option[] 
    "inoptions" ? component_shorewall_zones_option[] 
    "outoptions" ? component_shorewall_zones_option[]
};

type component_shorewall_interfaces_interface = string;

type component_shorewall_interfaces = {
    "zone" : component_shorewall_zones_zone 
    "interface" : component_shorewall_interfaces_interface
    "port" ? long(0..)
    "broadcast" ? string[]
    'options' ? string[] 
};


type component_shorewall_policy = {
    "src" : string
    "dst" : string
    "policy" : string
    "loglevel" ? string
    "burst" ? string
    "limit" ? string
    "connlimit" ? string
};


type component_shorewall_rules_action = string;

type component_shorewall_rules_srcdst = {
    ## zone: {zone|{all|any}[+][-]} $FW none
    "zone" : string 
    "interface" ? string
    ## this is an (mac)addres/range combo
    ## eg ~00-A0-C9-15-39-78,155.186.235.0/24!155.186.235.16/28
    "address" ? string[]
};

type component_shorewall_rules = {
    "action" : component_shorewall_rules_action
    "src" ? component_shorewall_rules_srcdst
    "dst" ? component_shorewall_rules_srcdst
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
};


type component_shorewall_shorewall = {
    "startup_enabled" : boolean
    "log_martians" ? boolean
    "clear_tc" ? boolean
    "adminisabsentminded" ? boolean
    "blacklistnewonly" ? boolean
    "pkttype" ? boolean
    "expand_policies" ? boolean
    "delete_then_add" ? boolean
    "auto_comment" ? boolean
    "mangle_enabled" ? boolean
    "restore_default_route" ? boolean
    "accounting" ? boolean
    "dynamic_blacklist" ? boolean
    "exportmodules" ? boolean
    
    "logtagonly" ? boolean
    "add_ip_aliases" ? boolean
    "add_snat_aliases" ? boolean
    "retain_aliases" ? boolean
    "tc_expert" ? boolean
    "mark_in_forward_chain" ? boolean
    "clampmss" ? boolean
    "route_filter" ? boolean
    "detect_dnat_ipaddrs" ? boolean
    "disable_ipv6" ? boolean
    "dynamic_zones" ? boolean
    "null_route_rfc1918" ? boolean
    "save_ipsets" ? boolean
    "mapoldactions" ? boolean
    "fastaccept" ? boolean
    "implicit_continue" ? boolean
    "high_route_marks" ? boolean
    "exportparams" ? boolean
    "keep_rt_tables" ? boolean
    "multicast" ? boolean
    "use_default_rt" ? boolean
    "automake" ? boolean
    "wide_tc_marks" ? boolean
    "track_providers" ? boolean
    "optimize_accounting" ? boolean
    "load_helpers_only" ? boolean
    "require_interface" ? boolean
    "complete" ? boolean

    ## string/no boolean
    "ip_forwarding" ? string with match(SELF,"(On|Off|Keep)")
    "verbosity" ? string
    "logfile" ? string
    "startup_log" ? string
    "log_verbosity" ? string
    "logformat" ? string
    "loglimit" ? string
    "logallnew" ? string
    "blacklist_loglevel" ? string
    "maclist_log_level" ? string
    "tcp_flags_log_level" ? string
    "smurf_log_level" ? string
    "iptables" ? string
    "ip" ? string
    "tc" ? string
    "ipset" ? string
    "perl" ? string
    "path" ? string
    "shorewall_shell" ? string
    "subsyslock" ? string
    "modulesdir" ? string
    "config_path" ? string
    "restorefile" ? string
    "ipsecfile" ? string
    "lockfile" ? string
    "drop_default" ? string
    "reject_default" ? string
    "accept_default" ? string
    "queue_default" ? string
    "nfqueue_default" ? string
    "rsh_command" ? string
    "rcp_command" ? string
    "tc_enabled" ? string
    "tc_priomap" ? string
    "mutex_timeout" ? string
    "module_suffix" ? string
    "maclist_table" ? string
    "maclist_ttl" ? string
    "optimize" ? string
    "dont_load" ? string
    "zone2zone" ? string
    "forward_clear_mark" ? string
    "blacklist_disposition" ? string
    "maclist_disposition" ? string
    "tcp_flags_disposition" ? string
};

type component_shorewall_type = {
    include structure_component
    "zones" : component_shorewall_zones[]
    "interfaces" : component_shorewall_interfaces[]
    "policy" : component_shorewall_policy[]
    "rules" : component_shorewall_rules[]
    "shorewall" : component_shorewall_shorewall
};

bind "/software/components/shorewall" = component_shorewall_type;

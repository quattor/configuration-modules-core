# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/gmond/schema;

include {'quattor/schema'};

type structure_component_gmond_acl_access = {
    "ip"                        : type_ip
    "mask"                      : long
    "action"                    : string with match(SELF, "allow|deny")
};

type structure_component_gmond_acl = {
    "default"                   : string with match(SELF, "allow|deny")
    "access"                    : structure_component_gmond_acl_access
};

type structure_component_gmond_cluster = {
    "name"                      ? string = "unspecified"
    "owner"                     ? string = "unspecified"
    "latlong"                   ? string = "unspecified"
    "url"                       ? type_absoluteURI
};

type structure_component_gmond_host = {
    "location"                  : string = "unspecified"
};

type structure_component_gmond_globals = {
    "daemonize"                 ? boolean = true
    "setuid"                    ? boolean = true
    "user"                      ? string = "nobody"
    "debug_level"               ? long = 0
    "mute"                      ? boolean = false
    "deaf"                      ? boolean = false
    "host_dmax"                 ? long(0..) = 0
    "cleanup_threshold"         ? long(0..) = 0
    "gexec"                     ? boolean = false
    "send_metadata_interval"    ? long(0..) = 0
    "module_dir"                ? string
};

type structure_component_gmond_udp_send_channel = {
    "mcast_join"                ? type_ipv4
    "mcast_if"                  ? string
    "host"                      ? type_hostname
    "port"                      : type_port
    "ttl"                       ? long(1..)
};

type structure_component_gmond_udp_recv_channel = {
    "mcast_join"                ? type_ipv4
    "bind"                      ? type_ip
    "mcast_if"                  ? string
    "port"                      : type_port
    "family"                    ? string = "inet4" with match(SELF, "inet[46]")
    "acl"                       ? structure_component_gmond_acl
};

type structure_component_gmond_tcp_accept_channel = {
    "bind"                      ? type_ip
    "port"                      : type_port
    "family"                    ? string = "inet4" with match(SELF, "inet[46]")
    "timeout"                   ? long = 1000000                    # micro seconds
    # "interface"               ? string                            # defined but not implemented
    "acl"                       ? structure_component_gmond_acl
};

type structure_component_gmond_metric = {
    "name"                      : string
    "value_threshold"           ? double
    "title"                     ? string
};

type structure_component_gmond_collection_group = {
    "collect_once"              ? boolean
    "collect_every"             ? long(1..)
    "time_threshold"            ? long(1..) = 3600
    "metric"                    : structure_component_gmond_metric[]
};

type structure_component_gmond_module = {
    "name"                      : string
    "language"                  ? string
    "path"                      ? string
    "params"                    ? string
    "param"                     ? nlist
};

type structure_component_gmond = {
    include structure_component
    "cluster"           ? structure_component_gmond_cluster
    "host"              ? structure_component_gmond_host
    "globals"           : structure_component_gmond_globals
    "udp_send_channel"  : structure_component_gmond_udp_send_channel[]
    "udp_recv_channel"  : structure_component_gmond_udp_recv_channel[]
    "tcp_accept_channel": structure_component_gmond_tcp_accept_channel[]
    "collection_group"  : structure_component_gmond_collection_group[]
    "module"            ? structure_component_gmond_module[]
    "include"           ? string[]
    "file"              : string                    # location of the configuration file
                                                    # differs between Ganglia 3.0 and 3.1
};

bind "/software/components/gmond" = structure_component_gmond;

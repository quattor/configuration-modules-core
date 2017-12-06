${componentschema}

include 'quattor/types/component';
include 'pan/types';

type gmond_acl_access = {
    "ip" : type_ip
    "mask" : long(0..32)
    "action" : string with match(SELF, "^(allow|deny)$")
};

type gmond_acl = {
    "default" : string with match(SELF, "^(allow|deny)$")
    "access" : gmond_acl_access
};

type gmond_cluster = {
    "name" ? string = "unspecified"
    "owner" ? string = "unspecified"
    "latlong" ? string = "unspecified"
    "url" ? type_absoluteURI
};

type gmond_host = {
    "location" : string = "unspecified"
};

type gmond_globals = {
    "daemonize" ? boolean = true
    "setuid" ? boolean = true
    "user" ? string = "nobody"
    "debug_level" ? long = 0
    "mute" ? boolean = false
    "deaf" ? boolean = false
    "host_dmax" ? long(0..) = 0
    "host_tmax" ? long(0..) = 0
    "cleanup_threshold" ? long(0..) = 0
    "gexec" ? boolean = false
    "send_metadata_interval" ? long(0..) = 0
    "module_dir" ? string
    "allow_extra_data" ? boolean
    "max_udp_msg_len" ? long(0..65536)
};

type gmond_udp_send_channel = {
    "mcast_join" ? type_ipv4
    "mcast_if" ? string
    "host" ? type_hostname
    "port" : type_port
    "ttl" ? long(1..)
    "bind" ? type_ipv4
    "bind_hostname" ? boolean
} with {
    if (is_defined(SELF['bind']) && is_defined(SELF['bind_hostname'])) {
        error('bind and bind_hostname are mutually exclusive');
    };
    true;
};

type gmond_udp_recv_channel = {
    "mcast_join" ? type_ipv4
    "bind" ? type_ip
    "mcast_if" ? string
    "port" : type_port
    "family" ? string = "inet4" with match(SELF, "^inet[46]$")
    "acl" ? gmond_acl
};

type gmond_tcp_accept_channel = {
    "bind" ? type_ip
    "port" : type_port
    "family" ? string = "inet4" with match(SELF, "^inet[46]$")
    @{timeout in micro seconds}
    "timeout" ? long = 1000000
    "acl" ? gmond_acl
};

type gmond_metric = {
    "name" : string
    "value_threshold" ? double
    "title" ? string
};

type gmond_collection_group = {
    "collect_once" ? boolean
    "collect_every" ? long(1..)
    "time_threshold" ? long(1..) = 3600
    "metric" : gmond_metric[]
};

type gmond_module = {
    "name" : string
    "language" ? string
    "path" ? string
    "params" ? string
    "param" ? dict
};

type ${project.artifactId}_component = {
    include structure_component
    @{Cluster configuration}
    "cluster" ? gmond_cluster
    @{Host configuration}
    "host" ? gmond_host
    @{Configuration of gmond}
    "globals" : gmond_globals
    @{List of UDP channels to send information to.}
    "udp_send_channel" : gmond_udp_send_channel[]
    @{List of UDP channels to receive information from.}
    "udp_recv_channel" : gmond_udp_recv_channel[]
    @{List of TCP channels from which information is accepted.}
    "tcp_accept_channel": gmond_tcp_accept_channel[]
    @{List of collection groups}
    "collection_group" : gmond_collection_group[]
    @{List of modules}
    "module" ? gmond_module[]
    @{Optional list of additional files to include.}
    "include" ? absolute_file_path[]
    @{The location of the configuration file. The correct value differs between
      Ganglia 3.0 (/etc/gmond.conf) and 3.1 (/etc/ganglia/gmond.conf).
      There is no default value.}
    "file" : absolute_file_path
};

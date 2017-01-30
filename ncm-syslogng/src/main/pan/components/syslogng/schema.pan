# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/syslogng/schema;

include 'quattor/schema';

# Convenience definitions
type filterstring = string with
    exists("/software/components/syslogng/filters/" + SELF) || error("No filters with name " + SELF);
type srcstring = string with
    exists ("/software/components/syslogng/sources/" + SELF) || error ("No sources with name " + SELF);
type dststring = string with
    exists ("/software/components/syslogng/destinations/" + SELF) || error ("No destinations with name " + SELF);

type prioritystring = string with match (SELF, "^(emerg|alert|crit|err|warning|notice|info|debug)$");

# Common options for every destination
type structure_syslogng_dstcommon = {
    "log_fifo_size" ? long
    "fsync" ? boolean
    "flush_lines" ? long
    "flush_timeout" ? long
    "template" ? string
    "template_escape" ? boolean
    "timezone" ? string
    "ts_format" ? string
    "frac_digits" ? long
    "throttle" ? long
};

# Common options for files and pipes
type structure_syslogng_filepipe = {
    "path" : string
    "owner" ? string
    "group" ? string
    "perm" ? string
};

# File destination
type structure_syslogng_file_dest = {
    include structure_syslogng_filepipe
    include structure_syslogng_dstcommon
    "create_dirs" ? boolean
    "dir_owner" ? string
    "dir_group" ? string
    "overwrite_if_older" ? long
    "remove_if_older" ? long
};

# Pipe destination is just a restricted version of file destination.
type structure_syslogng_pipe_dest = {
    include structure_syslogng_filepipe
    include structure_syslogng_dstcommon
};

# Destination on unix sockets.
type structure_syslogng_sock_dest = {
    include structure_syslogng_dstcommon
    "so_broadcast" ? boolean
    "so_rcvbuf" ? long
    "so_sndbuf" ? long
};

type structure_syslogng_unixdgram_dest = {
    include structure_syslogng_dstcommon
    "so_broadcast" ? boolean
    "so_rcvbuf" ? long
    "so_sndbuf" ? long
    "path" : string
};


# Network destinations (udp/tcp).
type structure_syslogng_network_dest = {
    include structure_syslogng_sock_dest
    "localip" ? type_ip
    "localport" ? long
#    "destport" : long = 514
    "spoof_source" ? boolean
    "ip_ttl" ? long
    "ip_tos" ? long
    "ip" : type_ip
    "port" : long
};

# Output to a tty
type structure_syslogng_tty_dest = {
    include structure_syslogng_dstcommon
    "path" : string
};

# Output to a program
type structure_syslogng_program_dest = {
    include structure_syslogng_dstcommon
    "commandline" : string
};

# Structure that binds together all destination declarations.
type structure_syslogng_destinations = {
    "files" ? structure_syslogng_file_dest[]
    "pipes" ? structure_syslogng_pipe_dest[]
    "unixdgram" ? structure_syslogng_unixdgram_dest[]
    "unixstream" ? structure_syslogng_unixdgram_dest[]
    "udp" ? structure_syslogng_network_dest[]
    "tcp" ? structure_syslogng_network_dest[]
};

# Flags for a log statement.
type structure_syslogng_log_rule_flags = {
    "final" ? boolean
    "fallback" ? boolean
    "catchall" ? boolean
    "flow-control" ? boolean
};

# Common options for a source
type structure_syslogng_srccommon = {
    "flags" ? string with match (SELF, "^(no-parse|kernel)$")
    "log_msg_size" ? long
    "log_iw_size" ? long
    "log_fetch_limit" ? long
    "log_prefix" ? string
    "pad_size" ? long
    "follow_freq" ? long
    "time_zone" ? string
    "optional" ? boolean
    "keep_timestamp" ? boolean
};

# Internal (syslog-ng) source
type structure_syslogng_internal_src = {
    include structure_syslogng_srccommon
};

# Global options for sockets
type structure_syslogng_socksrc = {
    include structure_syslogng_srccommon
    "so_broadcast" : boolean = false
    "so_rcvbuf" : long = 0
    "so_sndbuf" : long = 0
    "so_keepalive" : boolean = false
};

# Unix socket source
type structure_syslogng_unixsock_src = {
    include structure_syslogng_socksrc
    "owner" : string = "root"
    "group" : string = "root"
    "perm" : long = 0666
    "path" : string
};

# Network socket source
type structure_syslogng_network_src = {
    include structure_syslogng_socksrc
    "ip_ttl" ? long
    "ip_tos" ? long
    "ip" : type_ip
    "port" : long (0..65536) = 514
};

# TCP socket source
type structure_syslogng_network_tcp_src = {
    include structure_syslogng_network_src
    "keep-alive" : boolean = true
    "max-connections" : long = 256
};

# File source
type structure_syslogng_filepipe_src = {
    include structure_syslogng_srccommon
    "path" : string
};

# Structure that ties together all sources.
type structure_syslogng_sources = {
    "files" ? structure_syslogng_filepipe_src[]
    "pipes" ? structure_syslogng_filepipe_src[]
    "internal" ? structure_syslogng_internal_src[]
    "unixdgram" ? structure_syslogng_unixsock_src[]
    "unixstream" ? structure_syslogng_unixsock_src[]
    "udp" ? structure_syslogng_network_src[]
    "tcp" ? structure_syslogng_network_tcp_src[]
};

# Defines a single filter. All its statements will be connected by OR
# operator. If you want them to be connected by AND operator, use
# several filters instead.
type structure_syslogng_filter = {
    "facility" ? long[]
    "level" ? prioritystring []
    "program" ? string
    "host" ? string
    "match" ? string
    "filter" ? filterstring[]
    "netmask" ? type_ip
    # Filter to be negated
    "exclude_filters" ? filterstring[]
};

# All the filters lie in here.
type structure_syslogng_filters = structure_syslogng_filter{};

# Defines a log path
type structure_syslogng_log_rule = {
    "sources" : srcstring[]
    "destinations" : dststring[]
    "filters" ? filterstring[]
    "flags" ? structure_syslogng_log_rule_flags
};

# Log paths


# General syslog-ng options, global unless a driver overrides them.
type structure_syslogng_options = {
    "time_reopen" : long = 60
    "time_reap" : long = 60
    "time_sleep" : long = 0
#    "marq_freq" : long = 1200
    "stats_freq" : long = 600
    "log_fifo_size" : long = 100
    "chain_hostnames" : boolean = true
    "normalize_hostnames" : boolean = false
    "keep_hostname" : boolean = false
    "bad_hostname" ? string
    "create_dirs" : boolean = false
    "owner" : string = "root"
    "group" : string = "root"
    "perm" : long = 0600
    "dir_owner" : string = "root"
    "dir_group" : string = "root"
    "dir_perm" : long = 0700
    "ts_format" : string = "rfc3164"
    "use_dns" : string with match (SELF, "yes|no|persist_only")
    "dns_cache" : boolean = true
    "dns_cache_size" : long = 1007
    "dns_cache_expire" : long = 3600
#    "dns_cache_expire_time_failed" : long = 60
    "dns_cache_hosts" ? string
    "log_msg_size" : long = 8192
    "use_fqdn" : boolean = false
    "flush_lines" : long = 0
    "flush_timeout" : long = 10000
    "recv_time_zone" ? string
    "send_time_zone" ? string
    "frac_digits" : long = 0
    "sync" ? boolean = false
};


# The full definition for the component
type structure_component_syslogng = {
    include structure_component
    "options" : structure_syslogng_options
    "sources" : structure_syslogng_sources{}
    "destinations" : structure_syslogng_destinations{}
    "filters" ? structure_syslogng_filters
    "log_rules" : structure_syslogng_log_rule[]
};

bind "/software/components/syslogng" = structure_component_syslogng;

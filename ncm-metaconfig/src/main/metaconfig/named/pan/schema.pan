declaration template metaconfig/named/schema;

@{
    Data types for defining a Named configuration file.  For a full description please see
    https://www.centos.org/docs/2/rhl-rg-en-7.2/s1-bind-configuration.html
}

include 'pan/types';

type named_acl_name = string with
    exists ("/software/components/metaconfig/services/{/etc/named.conf}/contents/acls/" + SELF) ||
    match (SELF, "^(none|localhost|any|localnets)$") ||
    error ("ACL with name " + SELF + " is not defined");

type named_source = {
    "ip" ? type_ip
    "port" : type_port
};

type named_common_options = {
    "allow-recursion" ? named_acl_name[]
    "allow-transfer" ? named_acl_name[]
    "forwarders" ? type_ip[]
    "notify" : boolean = true
    "notify-source" ? named_source[]
    "transfer-source" ? named_source[]
};

@{
    Named options
}
type named_options = {
    include named_common_options
    "allow-query" : named_acl_name[]
    "forward" : choice('first', 'only') = "first"

    "bindkeys-file" : string = "/etc/named.iscdlv.key"
    "blackhole" ? named_acl_name[]
    "directory" : string = "/var/named"
    "dnssec-enable" : boolean = true
    "dnssec-lookaside" : string = 'auto'
    "dnssec-validation" : boolean = true
    "dump-file" : string = "/var/named/data/cache_dump.db"
    "empty-zones-enable" ? boolean
    "listen-on" ? type_ip[]
    "max-cache-size" ? long
    "memstatistics-file" : string = "/var/named/data/named_mem_stats.txt"
    "query-source" ? named_source[]
    "recursion" : boolean = true
    @{run rndc stats before anything is written to the statistics file}
    "statistics-file" : string = "/var/named/data/named_stats.txt"
    "zone-statistics" ? boolean
};

@{
    Named log channels
}
type named_log_channel = {
    "file" ? string
    "severity" : string
    "syslog" ? string
};

@{
    Named zones
}
type named_zone = {
    include named_common_options
    "allow-query" ? named_acl_name[]
    "forward" ? choice('first', 'only') = "first"

    "type" : choice("master", "slave", "hint", "forward")
    "transfers-in" ? long(1..)
    "transfers-out" ? long(1..)
    "file" ? string
    "name" : string
    "class" : string = "IN"
    "masters" ? type_ip[]
} with {
    if (SELF['type'] == 'forward') {
        if (!(exists(SELF['forward']) && exists(SELF['forwarders']))) {
            error("Missing forward and/or forwarders zone config for type forward for %s", SELF["name"]);
        };
        if (exists(SELF["file"])) {
            error("Cannot have file config for forward type for %s", SELF["name"]);
        };
    } else {
        if (exists(SELF['forward']) || exists(SELF['forwarders'])) {
            error("Cannot have forward and/or forwarders zone config and not type forward for %s", SELF["name"]);
        };
        if (!exists(SELF["file"])) {
            error("Missing file config for %s", SELF["name"]);
        };
    };
    true;
};

type named_channel_name = string with
    exists ("/software/components/metaconfig/services/{/etc/named.conf}/contents/logging/" + SELF) ||
    error (SELF + " doesn't refer to a logging channel");

@{
    Named log parameters
}
type named_logging = {
    "channels" : named_log_channel{}
    "category" : named_channel_name[]{}
};

type named_config = {
    "zones" ? named_zone[]
    "includes" ? string[]
    "logging" ? named_logging
    "options" : named_options
    "acls" ? type_network_name[]{}
};

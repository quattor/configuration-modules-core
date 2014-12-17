declaration template metaconfig/named/schema;

@{
    Data types for defining a Named configuration file.  For a full description please see
    https://www.centos.org/docs/2/rhl-rg-en-7.2/s1-bind-configuration.html
}

include 'pan/types';

type named_acl_name = string with exists ("/software/components/metaconfig/services/{/etc/named.conf}/contents/acls/" + SELF) ||
    match (SELF, "^(none|localhost|any|localnets)$") ||
    error ("ACL with name " + SELF + " is not defined");

type named_source = {
    "ip" ? type_ip
    "port" : type_port
};

@{
    Named options
}
type named_options = {
    "allow-query" : named_acl_name[]
    "allow-recursion" ? named_acl_name[]
    "allow-transfer" ? named_acl_name[]
    "blackhole" ? named_acl_name[]
    "forwarders" ? type_ip[]
    "listen-on" ? type_ip[]
    "notify" : boolean = true
    "recursion" : boolean = true
    "dnssec-enable" : boolean = true
    "dnssec-validation" : boolean = true
    "transfer-source" ? named_source[]
    "query-source" ? named_source[]
    "notify-source" ? named_source[]
    "directory" : string = "/var/named"
    "dump-file" : string = "/var/named/data/cache_dump.db"
    "statistics-file" : string = "/var/named/data/named_stats.txt"
    "memstatistics-file" : string = "/var/named/data/named_mem_stats.txt"
    "bindkeys-file" : string = "/etc/named.iscdlv.key"
    "dnssec-lookaside" : string = 'auto'
    "empty-zones-enable" ? boolean
    "forward" : string = "first" with match(SELF,'^(first|only)$')
    "max-cache-size" ? long
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
    "type" : string with match (SELF, "^(master|slave|hint)$")
    "transfers-in" ? long(1..)
    "transfers-out" ? long(1..)
    "file" : string
    "name" : string
    "class" : string = "IN"
    "masters" ? type_ip[]
};

type named_channel_name = string with exists ("/software/components/metaconfig/services/{/etc/named.conf}/contents/logging/" + SELF) ||
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


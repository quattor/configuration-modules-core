# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/squid/config-rpm;
include {'components/squid/schema'};

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${RELEASE}", "noarch");


# Common settings
#"/software/components/squid/dependencies/pre" = list("spma");
"/software/components/squid/active" ?= true;
"/software/components/squid/dispatch" ?= true;

#
# List of supported options (mostly oriented to 'reverse' caching). Adapt the
# tokens enclosed in '<>' to your needs.
#
# Basic options
#"/software/components/squid/basic/emulate_httpd_log" = <on|off>;
#"/software/components/squid/basic/http_port" = <squid-http-port>;
#"/software/components/squid/basic/httpd_accel_host" = "<your.backend.server>";
#"/software/components/squid/basic/httpd_accel_port" = <httpd-port-for-reverse-caching>;
    # set this to 'on' for "accelerator mode"
#"/software/components/squid/basic/httpd_accel_single_host" = "<on|off>";
#"/software/components/squid/basic/ignore_unknown_nameservers" = "<on|off>";
#"/software/components/squid/basic/log_fqdn" = "<on|off>";
#"/software/components/squid/basic/negative_dns_ttl" = "<number> <seconds|minutes|hours|days>";
#"/software/components/squid/basic/redirect_rewrites_host_header" = "<on|off>";
#"/software/components/squid/basic/store_objects_per_bucket" = <number>;

# Cache size and similia (all values are KB)
#"/software/components/squid/size/cache_mem" = <number>;
#"/software/components/squid/size/maximum_object_size" = <number>;
#"/software/components/squid/size/maximum_object_size_in_memory" = <number>;
#"/software/components/squid/size/range_offset_limit" = <number>;
#"/software/components/squid/size/store_avg_object_size" = <number>;

# Directives which may appear more than once.
# WARNING! This general schema is not yet fully supported, since
# context-dependant placement is needed for some directives. In order to avoid
# problems, define only *one* directive per type.
#
# Cache directories (a.k.a. swaps) definition:
#"/software/components/squid/multi/cache_dir" = list(
#   nlist(
#        "type", "<ufs|aufs|diskd>",
#        "directory", "<absolute-path>",
#        "MBsize", <number>,
#        "level1", <number>,
#        "level2", <number>
#   )
#);
#
# ACL definition. Note that each acl must appear before any reference to it!
# MANDATORY! You need to define at least a 'src' ACL for 'our_networks'!
#"/software/components/squid/multi/acl" = list(
#   nlist(
#       "name", "our_networks",
#       "type", "src",
#       "targets",  list(
#                       "<net1-address>/<net1-mask>",
#                       "<net2-address>/<net2-mask>",
#                       ...
#                   )
#   )
#);
#
# Who is [dis]allowed to connect via HTTP. Each directive must show up after
# any 'acl ...' directive referencing it, and (for security reasons) before any
# '*_access deny all' directive belonging to the same category!
# MANDATORY! You need to define at least an 'allow' directive for
# 'our_networks'!
#"/software/components/squid/multi/http_access" = list(
#   nlist(
#       "policy", "allow",
#       "acls", list("our_networks")
#   )
#);
#
# How to refresh cached contents:
#"/software/components/squid/multi/refresh_pattern" = list(
#   nlist(
#       "pattern", "<regular-expression>",
#       "min", <number>,
#       "percent", <number>,
#       "max", <number>
#   )
#);


# Enhanced DNS handling: for avoiding timeouts, better off specify DNS servers,
# ignore server names (useful when there's a DNS balancing providing different
# servers) and never cache failed lookups:
#"/software/components/squid/multi/dns_nameservers" = list(<ip-address>, ...);
    # f.i., this is for CERN
    #"/software/components/squid/multi/dns_nameservers" = list(
    #    "137.138.17.5",
    #    "137.138.16.5"
    #);
#"/software/components/squid/basic/ignore_unknown_nameservers" = "off";
#"/software/components/squid/basic/negative_dns_ttl" = "1 seconds";

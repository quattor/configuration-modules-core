declaration template metaconfig/nginx/schema;

include 'pan/types';

@{
    Data types for an nginx server, with proxy and SSL support
}

type cipherstring = string with match(SELF, "^(TLSv1|TLSv1.1|TLSv1.2)$")
    || error("Use a modern cipher suite, for Pete's sake!");

type basic_ssl = {
    "options" ? string[]
    "requiressl" ? boolean
    "verify_client" ? string with match(SELF, "^(require|none|optional|optional_no_ca)$")
    "require" ? string
};

type httpd_ssl = {
    include basic_ssl
    "active" : boolean = true
    "ciphersuite" : cipherstring[] = list("TLSv1")
    "protocol" : cipherstring[] = list("TLSv1")
    "certificate" : string
    "key" : string
    "ca"  ? string
    "certificate_chain_file" ? string
    "revocation_file" ? string
};

@{ Basic nginx declarations. So far we only need to declare how many
    processes and how many connections per process.
}
type nginx_global = {
    "worker_processes" : long = 4
    "worker_connections" : long = 1024
};

@{
    Description of a proxy_cache_path line
}
type nginx_cache_path = {
    "path" : string
    "levels" : long(1..2)[] = list(1,2)
    # Sizes in MBs to keep things readable
    "keys_zone" : long{}
    "max_size" ? long
    # In minutes
    "inactive" ? long = 60
};

type nginx_cache_valid_period = {
    "codes" : long[]
    # In minutes
    "period" : long
};

@{
    Configuration entries related to a caching proxy
}
type nginx_proxy_cache = {
    "valid" ? nginx_cache_valid_period[]
    "redirect" ? type_absoluteURI[2]
    "cache" : string
};

@{ Configuration entries for a proxy, that should lie in a "location"
    section.
}
type nginx_proxy_location = {
    "set_header" ? string{}
    "redirect" ? string
    "next_upstream" ? string
    "cache" ? nginx_proxy_cache
    "pass" : type_absoluteURI
};

@{
    Structure of a location entry
}
type nginx_location = {
    "root" ? string
    "name" : string
    "operator" ? string with match(SELF, "^(=|^~|~*)$")
    "proxy" ? nginx_proxy_location
};


@{
    Description of an nginx error_page line
}
type nginx_error_page = {
    "error_codes" : long[]
    "file" : string
};

type nginx_listen = {
    "addr" ? type_hostport
    "default" : boolean = false
    "ssl" : boolean = false
};


@{
    An nginx server entry.
}
type nginx_server = {
    "includes" ? string[]
    "listen" : nginx_listen
    "name" : type_hostname[]
    "location" : nginx_location[]
    "error_page" : nginx_error_page[] = list()
    "ssl" ? httpd_ssl
};

@{ An upstream declaration for reverse proxies
}
type nginx_upstream = {
    "host" : type_hostport[]
    "ip_hash" : boolean = false
};

@{ Configuration of an HTTP instance. Some basic things will not
    change and are hardcoded in the TT template, anyways.
}
type nginx_http = {
    "includes" : string[]
    "default_type" : string = "application/octet-stream"
    "gzip" : boolean = true
    "proxy_cache_path" ? nginx_cache_path[]
    "server" : nginx_server[]
    "keepalive_timeout" : long = 65
    "upstream" ? nginx_upstream{}
};

type type_nginx = {
    "global" : nginx_global
    "http" : nginx_http[]
};


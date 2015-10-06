declaration template metaconfig/httpd/2.4/schema;

include 'metaconfig/httpd/types_simple';

# 2.4 specific types

# TODO add support for new authz_host syntax require ip / require host

type httpd_limit = {
    include httpd_limit_base
    "access" ? httpd_acl # provided via mod_access_compat
    "authz" ? httpd_authz[]
};

type httpd_file = {
    include httpd_file_base
    "access" ? httpd_acl # provided via mod_access_compat
    "authz" ? httpd_authz[]
};

type httpd_includes = {
    "includes" : string[] = list("conf.modules.d/*.conf")
    "includesoptional" : string[] = list("conf.d/*.conf")
};

include 'metaconfig/httpd/types_composed';

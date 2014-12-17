declaration template metaconfig/perfsonar/lookup/registration/schema;

include 'pan/types';

type ls_service = {
    "type" : string
    "port" ? type_port
};

type ls_reg_site = {
    "site_name" : string
    "site_location" : string
    "is_local" : boolean = true
    "site_project" : string[]
    "address" :  type_fqdn
    "service" : ls_service[]
};

type ls_registration = {
    "site" : ls_reg_site[]
    # In seconds
    "check_interval" : long(0..) = 60
    # In hours
    "ls_interval" : long(0..) = 6
    "require_site_name" : boolean = true
    "require_site_location" : boolean = true
    "ls_instance" : type_URI
    "allow_internal_addresses" : boolean = false
};


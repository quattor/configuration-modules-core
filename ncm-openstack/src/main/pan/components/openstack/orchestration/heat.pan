# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/openstack/orchestration/heat;

include 'components/openstack/identity';


@documentation{
    Heat default section
}
type openstack_heat_DEFAULTS = {
    include openstack_DEFAULTS
    @{URL of the Heat metadata server. NOTE: Setting this is only needed if you
    require instances to use a different endpoint than in the keystone catalog}
    'heat_metadata_server_url' ? type_absoluteURI
    @{URL of the Heat waitcondition server}
    'heat_waitcondition_server_url' : type_absoluteURI
    @{Keystone username, a user with roles sufficient to manage users and projects
    in the stack_user_domain}
    'stack_domain_admin' : string
    @{Keystone password for stack_domain_admin user}
    'stack_domain_admin_password' : string
    @{Keystone domain name which contains heat template-defined users. If
    "stack_user_domain_id" option is set, this option is ignored}
    'stack_user_domain_name' : string = 'heat'
};

@documentation{
    Heat clients_keystone section
}
type openstack_heat_clients_keystone = {
    @{Unversioned keystone url in format like http://0.0.0.0:5000}
    'auth_uri' : type_absoluteURI
};

type openstack_quattor_heat = openstack_quattor;

@documentation{
    list of Heat configuration sections
}
type openstack_heat_config = {
    'DEFAULT' : openstack_heat_DEFAULTS
    'database' : openstack_database
    'keystone_authtoken' : openstack_keystone_authtoken
    'trustee' : openstack_domains_common
    'clients_keystone' : openstack_heat_clients_keystone
    'quattor' : openstack_quattor_heat

};

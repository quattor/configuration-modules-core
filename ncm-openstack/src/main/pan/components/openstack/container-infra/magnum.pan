# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/openstack/container-infra/magnum;

include 'components/openstack/identity';

@documentation{
    Magnum api section
}
type openstack_magnum_api = {
    @{The listen IP for the Magnum API server}
    'host' : type_ip
};

@documentation{
    Magnum certificates section
}
type openstack_magnum_certificates = {
    @{Certificate Manager plugin.
    Barbican is recommended for production environments}
    'cert_manager_type' : choice('barbican', 'x509keypair') = 'barbican'
} = dict();

@documentation{
    Magnum Cinder client section
}
type openstack_magnum_cinder_client = {
    @{Region in Identity service catalog to use for communication with the
    OpenStack service}
    'region_name' : string = 'RegionOne'
} = dict();

@documentation{
    Magnum trust section
}
type openstack_magnum_trust = {
    @{Name of the domain to create trustee for}
    'trustee_domain_name' : string = 'magnum'
    @{Name of the admin with roles sufficient to manage users in the trustee_domain}
    'trustee_domain_admin_name' : string = 'magnum_domain_admin'
    @{Password of trustee_domain_admin}
    'trustee_domain_admin_password' : string
    @{Auth interface used by instances/trustee}
    'trustee_keystone_interface' : choice('public', 'internal') = 'public'
};

@documentation{
    Magnum keystone_auth section
}
type openstack_magnum_keystone_auth = {
    @{Config Section from which to load plugin specific options}
    'auth_section' : string = 'keystone_authtoken'
} = dict();

@documentation{
    Magnum cinder section
}
type openstack_magnum_cinder = {
    @{The default docker volume_type to use for volumes used for docker storage.
    To use the cinder volumes for docker storage, you need to select a default
    value}
    'default_docker_volume_type' : string
};

type openstack_quattor_magnum = openstack_quattor;

@documentation{
    list of Magnum configuration sections
}
type openstack_magnum_config = {
    'DEFAULT' : openstack_DEFAULTS
    'database' : openstack_database
    'keystone_authtoken' : openstack_keystone_authtoken
    'keystone_auth' : openstack_magnum_keystone_auth
    'oslo_messaging_notifications' : openstack_oslo_messaging_notifications
    'oslo_concurrency' : openstack_oslo_concurrency
    'api' : openstack_magnum_api
    'certificates' : openstack_magnum_certificates
    'cinder_client' : openstack_magnum_cinder_client
    'cinder' ? openstack_magnum_cinder
    'trust' : openstack_magnum_trust
    'quattor' : openstack_quattor_magnum
};

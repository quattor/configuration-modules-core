# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/openstack/catalog/murano;

include 'components/openstack/identity';

@documentation{
    Murano authtoken section
}
type openstack_murano_authtoken = {
    include openstack_keystone_authtoken
    @{Service tenant name (aka project)
    Murano should be included within service project with admin role}
    'admin_tenant_name' : string = 'service'
    @{Service username}
    'admin_user' : string = 'murano'
    @{Service user password}
    'admin_password' : string
    @{Complete admin Identity API endpoint. This should specify the
    unversioned root endpoint e.g. https://localhost:35357/}
    'identity_uri' : type_absoluteURI
};

@documentation{
    Murano rabbitmq section
}
type openstack_murano_rabbitmq = {
    @{The RabbitMQ broker address which used for communication with Murano
    guest agents}
    'host' : type_hostname
    @{The RabbitMQ login}
    'login' : string = 'openstack'
    @{The RabbitMQ password}
    'password' : string
    @{The RabbitMQ virtual host}
    'virtual_host' : string = '/'
};

@documentation{
    Murano networking section
}
type openstack_murano_networking = {
    @{List of default DNS nameservers to be assigned to created Networks.
    Set to 8.8.8.8 by default in case openstack neutron has no default DNS configured}
    'default_dns' : type_ip[] = list('8.8.8.8')
    @{Network driver to use. Options are neutron or nova. If not provided,
    the driver will be detected}
    'driver' ? choice('neutron', 'nova')
    @{This option will create a router when one with "router_name" does
    not exist}
    'create_router' ? boolean
};

@documentation{
    Murano section
}
type openstack_murano = {
    @{Optional murano url in format like http://0.0.0.0:8082 used by
    Murano engine}
    'url' : type_absoluteURI
};

@documentation{
    list of Murano configuration sections
}
type openstack_murano_config = {
    'DEFAULT' ? openstack_DEFAULTS
    'database' : openstack_database
    'keystone_authtoken' : openstack_murano_authtoken
    'rabbitmq' : openstack_murano_rabbitmq
    'murano' : openstack_murano
    'networking' ? openstack_murano_networking
};

# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/openstack/rating/cloudkitty;

include 'components/openstack/identity';

@documentation{
    Cloudkitty common authentication section
}
type openstack_cloudkitty_auth_section = {
    'auth_section' : string = 'keystone_authtoken'
    'keystone_version' ? long(2..3)
};

@documentation{
    The Cloudkitty configuration options in the "tenant_fetcher" Section.
}
type openstack_cloudkitty_tenant_fetcher = {
    'backend' : string = 'keystone'
};

@documentation{
    The Cloudkitty configuration options in the "storage" Section.
}
type openstack_cloudkitty_storage = {
    @{Two storage backends are available: sqlalchemy and hybrid
    (SQLalchemy being the recommended one)}
    'backend' : choice('sqlalchemy', 'hybrid') = 'sqlalchemy'
    @{A v2 backend storage is also available. Whether its implementation nor
    its API are considered stable yet, and it will evolve during the Stein cycle.
    It is available for development purposes only}
    'version' : long(1..2) = 1
};

@documentation{
    The Cloudkitty configuration options in the "collect" Section.
}
type openstack_cloudkitty_collect = {
    @{The collect information, is separated from the Cloudkitty
    configuration file, in a yaml one.
    This allows Cloudkitty users to change metrology configuration,
    without modifying source code or Cloudkitty configuration file}
    'metrics_conf' : absolute_file_path = '/etc/cloudkitty/metrics.yml'
};

type openstack_quattor_cloudkitty = openstack_quattor;

@documentation{
    list of Cloudkitty configuration sections
}
type openstack_cloudkitty_config = {
    'DEFAULT' : openstack_DEFAULTS
    'database' : openstack_database
    'keystone_authtoken' : openstack_keystone_authtoken
    'keystone_fetcher' : openstack_cloudkitty_auth_section
    'tenant_fetcher' : openstack_cloudkitty_tenant_fetcher
    'storage' : openstack_cloudkitty_storage
    'storage_gnocchi' ? openstack_cloudkitty_auth_section
    'collect' : openstack_cloudkitty_collect
    'gnocchi_collector' : openstack_cloudkitty_auth_section
    'quattor' : openstack_quattor_cloudkitty
};

# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/openstack/metric/ceilometer;

include 'components/openstack/identity';



@documentation{
    list of Gnocchi api section
}
type openstack_ceilometer_gnocchi_api = {
    'auth_mode' : string = 'keystone'
};


@documentation{
    list of Gnocchi indexer section
}
type openstack_ceilometer_gnocchi_indexer = {
    @{The SQLAlchemy connection string to use to connect to the database}
    'url' : string
};

@documentation{
    list of Gnocchi storage section
}
type openstack_ceilometer_gnocchi_storage = {
    'file_basepath' : absolute_file_path = '/var/lib/gnocchi'
    'driver' : string = 'file'
} = dict();


@documentation{
    list of Ceilometer Gnocchi service sections
}
type openstack_ceilometer_gnocchi_config = {
    'api' : openstack_ceilometer_gnocchi_api
    'indexer' : openstack_ceilometer_gnocchi_indexer
    'storage' : openstack_ceilometer_gnocchi_storage
    'keystone_authtoken' : openstack_domains_common
};

@documentation{
    list of Ceilometer service configuration sections
}
type openstack_ceilometer_service_config = {
    'DEFAULT' : openstack_DEFAULTS
    'service_credentials' : openstack_domains_common
};

type openstack_quattor_ceilometer = openstack_quattor;

@documentation{
    list of Ceilometer service configuration sections
}
type openstack_ceilometer_config = {
    'service' ? openstack_ceilometer_service_config
    'gnocchi' ? openstack_ceilometer_gnocchi_config
    # pipeline in yaml format
    #'pipeline' ? openstack_ceilometer_pipeline_config
    # default empty dict for pure hypervisor
    'quattor' : openstack_quattor_ceilometer = dict()
};

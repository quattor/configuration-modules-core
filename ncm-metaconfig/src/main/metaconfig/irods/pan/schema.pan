declaration template metaconfig/irods/schema;

include 'pan/types';

@{ type for configuring the irods_environment.json config file for clients @}
type irods_environment_client_config = {
    'irods_host' :  type_hostname
    'irods_port' : type_port
    'irods_user_name' : string
    'irods_zone_name' : string
};
@{ type for configuring the irods_environment.json config file for service accounts @}
type irods_environment_service_config = {
    include irods_environment_client_config
};

@{ type for configuring the irods_hosts.json address config section @}
type irods_host_entry_address = {
    'address' : type_hostname
};

@{ type for configuring the irods_hosts.json host_entries config section @}
type irods_host_entry = {
    'address_type' : choice('local', 'remote')
    'addresses' : irods_host_entry_address[]
};

@{ type for configuring the irods_hosts.json config file @}
type irods_hosts_config = {
    'host_entries' : irods_host_entry[]
};

declaration template metaconfig/nova/schema;

include 'pan/types';

type nova_default = {
    'cert' :  string
    'key' : string
    'force_config_drive' : boolean
    'reclaim_instance_interval' : long
    'scheduler_max_attempts' : long
    'scheduler_default_filters' : list
    'pci_alias' : list
    'auth_strategy' : string
    'cpu_allocation_ratio' : long
    'debug' : boolean
    'enabled_apis' : list
    'firewall_driver' : string
    'linuxnet_interface_driver' : string
    'memcached_servers' : string
    'my_ip' : string
    'network_api_class' : string
    'ooi_listen_port' : long
    'ram_allocation_ratio' : long
    'rpc_backend' : string
    'security_group_api' : string
    'verbose' : boolean
};

type nova_glance = {
    'api_servers' : string
};

type nova_api_database = {
    'connection' : string
};

type nova_cache = {
    'backend' : string
    'enabled' : boolean
    'memcached_servers' : string
};

type nova_database = {
    'connection' : string
};

type nova_keystone_authtoken = {
    'auth_plugin' : string
    'auth_type' : string
    'auth_uri' : string
    'auth_url' : string
    'memcached_servers' : string
    'password' : string
    'project_domain_name' : string
    'project_name' : string
    'user_domain_name' : string
    'username' : string
};

type nova_neutron = {
    'auth_plugin' : string
    'auth_type' : string
    'auth_url' : string
    'metadata_proxy_shared_secret' : string
    'password' : string
    'project_domain_name' : string
    'project_name' : string
    'region_name' : string
    'service_metadata_proxy' : boolean
    'url' : string
    'user_domain_name' : string
    'username' : string
};

type nova_oslo_concurrency = {
    'lock_path' : string
};

type nova_oslo_messaging_rabbit = {
    'rabbit_hosts' : string
    'rabbit_password' : string
    'rabbit_userid' : string
};

type nova_vnc = {
    'vncserver_listen' : string
    'vncserver_proxyclient_address' : string
};

type nova_config = {
    'DEFAULT' : nova_default
    'glance' : nova_glance
    'api_database' : nova_api_database
    'cache' : nova_cache
    'database' : nova_database
    'keystone_authtoken' : nova_keystone_authtoken
    'neutron' : nova_neutron
    'oslo_concurrency' : nova_oslo_concurrency
    'oslo_messaging_rabbit' : nova_oslo_messaging_rabbit
    'vnc' : nova_vnc
};

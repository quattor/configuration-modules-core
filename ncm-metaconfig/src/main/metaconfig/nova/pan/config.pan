unique template metaconfig/nova/config;

include 'metaconfig/nova/schema';

bind "/software/components/metaconfig/services/{/etc/nova/nova.conf}/contents" = nova_config;


prefix "/software/components/metaconfig/services/{/etc/nova/nova.conf}";
"module" = "nova/main";
"contents" = dict(
"DEFAULT", dict(
"cert", "/etc/certlocation/cert.pem",
"key", "/etc/certlocation/key.pem",
"force_config_drive", true,
"reclaim_instance_interval", 0,
"scheduler_max_attempts", 20,
"scheduler_default_filters", list(
    'RetryFilter',
    'AvailabilityZoneFilter',
    'AggregateRamFilter',
    'AggregateDiskFilter',
    'AggregateCoreFilter',
    'ComputeFilter',
    'ComputeCapabilitiesFilter',
    'ImagePropertiesFilter',
    'ServerGroupAntiAffinityFilter',
    'ServerGroupAffinityFilter',
    'NUMATopologyFilter',
    'AggregateInstanceExtraSpecsFilter',
    'PciPassthroughFilter',
),
"pci_alias", list(
    '{ "vendor_id":"10de", "product_id":"13bb", "device_type":"type-PCI", "name":"nvidia-quadro-k620-vga"}',
    '{ "vendor_id":"11de", "product_id":"14bb", "device_type":"type-PCI", "name":"nvidia-quadro-k621-vga"}',
),
"auth_strategy", "keystone",
"cpu_allocation_ratio", 4,
"debug", false,
"enabled_apis", list(
'osapi_compute',
'metadata',
'ooi',
),
"firewall_driver", "nova.virt.firewall.NoopFirewallDriver",
"linuxnet_interface_driver", "nova.network.linux_net.NeutronLinuxBridgeInterfaceDriver",
"memcached_servers", "keystone1.openstack.uk:9000",
"my_ip", "127.0.0.1",
"network_api_class", "nova.network.neutronv2.api.API",
"ooi_listen_port", 9000,
"ram_allocation_ratio", 4,
"rpc_backend", "rabbit",
"security_group_api", "neutron",
"verbose", true,
),
"glance", dict(
"api_servers", format('http://%s:9000', 'openstack.uk'),
),
"api_database", dict(
"connection", "mysql+pymysql://nova:meepmorp@openstack.uk:9000/nova_api",
),
"cache", dict(
"backend", "oslo_cache.memcache_pool",
"enabled", true,
"memcached_servers", "keystone1.openstack.uk:9000"
),
"database", dict(
"connection", "mysql+pymysql://nova:meepmorp@openstack.uk:9000/nova",
),
"keystone_authtoken", dict(
"auth_plugin", "password",
"auth_type", "password",
"auth_uri", "https://openstack.uk:9000",
"auth_url", "https://openstack.uk:9000",
"memcached_servers", "keystone1.openstack.uk:9000",
"password", "meepmorp",
"project_domain_name", "default",
"project_name", "service",
"user_domain_name", "default",
"username", "nova",
),
"neutron", dict(
"auth_plugin", "password",
"auth_type", "password",
"auth_url", "https://openstack.uk:9000",
"metadata_proxy_shared_secret", "meepmorp",
"password", "meepmorp",
"project_domain_name", "default",
"project_name", "service",
"region_name", "RegionOne",
"service_metadata_proxy", true,
"url", "https://openstack.uk:9000",
"user_domain_name", "default",
"username", "neutron",
),
"oslo_concurrency", dict(
"lock_path", "/var/lib/nova/tmp",
),
"oslo_messaging_rabbit", dict(
"rabbit_hosts", "rabbit1.openstack.uk:9000",
"rabbit_password", "meepmorp",
"rabbit_userid", "openstack",
),
"vnc", dict(
"vncserver_listen", "*",
"vncserver_proxyclient_address", "*",
),
);

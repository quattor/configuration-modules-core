template os_resources;


include 'common_resources';


# Identity/ keystone section
include 'components/openstack/identity/gather/identity/keystone';

prefix "/software/components/openstack/identity";

prefix "keystone";
"database" = dict(
    "connection", "mysql+pymysql://keystone:keystone_db_pass@controller.mysite.com/keystone",
);

prefix "client/region";
"regionOne/description" = "abc";
"regionTwo/description" = "def";
"regionThree/description" = "xyz";
"regionThree/parent_region_id" = "regionTwo";

prefix "client/domain";
"vo1/description" = "vo1";
"vo2/description" = "vo2";

prefix "client/project/service";
"description" = "main service project";
"domain_id" = "default";

prefix "client/project/vo1";
"description" = "main vo1 project";
"domain_id" = "vo1";
prefix "client/project/realproject";
"description" = "some real project";
"parent_id" = "vo1";
# no description
prefix "client/project";
"opq" = dict();

prefix "client/project/vo2";
"description" = "main vo2 project";
"domain_id" = "vo2";

prefix "client/user/user1";
"description" = "first user";
"password" = "abc";

prefix "client/group/grp1";
"description" = "first group";
"domain_id" = "vo2";

prefix "client/role";
"rl1" = dict();
"rl2" = dict();

prefix "client/rolemap";
"domain/vo1/user/user1" = list('rl1');
"project/vo2/group/grp1" = list('rl2');


prefix "client/service/glanceone";
"description" = "OS image one";
"type" = "image";

prefix "client/endpoint/glanceone";
"internal/url/0" = "http://internal0";
"internal/url/1" = "http://internal1";
"public/url/0" = "http://public";
"public/region" = "regionThree";
"admin/url/0" = "http://admin";


# Glance/service section
include 'components/openstack/identity/gather/image/glance';

prefix "/software/components/openstack/image/glance/service";
"DEFAULT" = dict(
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
);
"database" = dict(
    "connection", format("mysql+pymysql://glance:glance_db_pass@%s/glance", OPENSTACK_HOST_SERVER),
);
"keystone_authtoken" = dict(
    "auth_uri", format('http://%s:5000', OPENSTACK_HOST_SERVER),
    "auth_url", format('http://%s:35357', OPENSTACK_HOST_SERVER),
    "username", "glance",
    "password", "glance_good_password",
    "memcached_servers", list('controller.mysite.com:11211'),
);
"glance_store" = dict(
    "default_store", "file",
);
"oslo_messaging_notifications" = dict(
    "driver", "messagingv2",
);


# Glance/registry section

prefix "/software/components/openstack/image/glance/registry";
"DEFAULT" = dict(
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
);
"database" = dict(
    "connection", format("mysql+pymysql://glance:glance_db_pass@%s/glance", OPENSTACK_HOST_SERVER),
);
"keystone_authtoken" = dict(
    "auth_uri", format('http://%s:5000', OPENSTACK_HOST_SERVER),
    "auth_url", format('http://%s:35357', OPENSTACK_HOST_SERVER),
    "username", "glance",
    "password", "glance_good_password",
    "memcached_servers", list('controller.mysite.com:11211'),
);
"oslo_messaging_notifications" = dict(
    "driver", "messagingv2",
);


# Horizon section

prefix "/software/components/openstack/dashboard/horizon";
"allowed_hosts" = list('*');
"openstack_keystone_url" = 'http://controller.mysite.com:5000/v3';
"caches/default" = dict(
    "LOCATION", list('controller.mysite.com:11211'),
);
"openstack_keystone_multidomain_support" = true;
"time_zone" = "Europe/Brussels";
"secret_key" = "d5ae8703f268f0effff111";


# Neutron section

include 'components/openstack/identity/gather/network/neutron';
prefix "/software/components/openstack/network/neutron/service";
"database" = dict(
    "connection", format("mysql+pymysql://neutron:neutron_db_pass@%s/neutron", OPENSTACK_HOST_SERVER),
);
"DEFAULT" = dict(
    "auth_strategy", "keystone",
    "core_plugin", "ml2",
    "service_plugins", list('router', 'port_forwarding'),
    "allow_overlapping_ips", true,
    "notify_nova_on_port_status_changes", true,
    "notify_nova_on_port_data_changes", true,
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
);
"nova" = dict(
    "auth_url", format('http://%s:35357', OPENSTACK_HOST_SERVER),
    "username", "nova",
    "password", "nova_good_password",
);
"oslo_messaging_notifications" = dict(
    "driver", "messagingv2",
);


# Neutron/DHCP section

prefix "/software/components/openstack/network/neutron/dhcp";
"DEFAULT" = dict(
    "interface_driver", "linuxbridge",
    "dhcp_driver", "neutron.agent.linux.dhcp.Dnsmasq",
    "enable_isolated_metadata", true,
);


# Neutron/L3 section

prefix "/software/components/openstack/network/neutron/l3";
"DEFAULT" = dict(
    "interface_driver", "linuxbridge",
);


# Neutron/Metadata section

prefix "/software/components/openstack/network/neutron/metadata";
"DEFAULT" = dict(
    "nova_metadata_host", "controller.mysite.com",
    "metadata_proxy_shared_secret", "metadata_good_password",
);


# Neutron/ML2 section

prefix "/software/components/openstack/network/neutron/ml2";
"ml2_type_vxlan" = dict(
    'vni_ranges', '1:1000',
);
"securitygroup" = dict(
    "enable_security_group", true,
    "firewall_driver", "neutron.agent.linux.iptables_firewall.IptablesFirewallDriver",
);

# Cinder section
include 'components/openstack/identity/gather/volume/cinder';
prefix "/software/components/openstack/volume/cinder";

"DEFAULT" = dict(
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
    "auth_strategy", "keystone",
    "enabled_backends", list('ceph', 'lvm'),
    "my_ip", '1.2.3.4',
);
"database" = dict(
    "connection", format("mysql+pymysql://cinder:cinder_db_pass@%s/cinder", OPENSTACK_HOST_SERVER),
);
"keystone_authtoken" = dict(
    "auth_uri", format('http://%s:5000', OPENSTACK_HOST_SERVER),
    "auth_url", format('http://%s:35357', OPENSTACK_HOST_SERVER),
    "username", "cinder",
    "password", "cinder_good_password",
    "memcached_servers", list('controller.mysite.com:11211'),
);
"oslo_concurrency" = dict(
    "lock_path", "/var/lib/cinder/tmp",
);
# LVM storage setup
"lvm" = dict(
    "volume_group", "lvm-volumes",
);
# Ceph backend setup
"ceph" = dict(
    "volume_backend_name", "ceph",
    "rbd_pool", "volumes",
    "rbd_user", "volumes",
    "rbd_secret_uuid", "a5d0dd94-57c4-ae55-ffe0-7e3732a24455",
);
"oslo_messaging_notifications" = dict(
    "driver", "messagingv2",
);



# Nova section

include 'components/openstack/identity/gather/compute/nova';
prefix "/software/components/openstack/compute/nova";
"database" = dict(
    "connection", format("mysql+pymysql://nova:nova_db_pass@%s/nova", OPENSTACK_HOST_SERVER),
);
"api_database" = dict(
    "connection", format("mysql+pymysql://nova:nova_db_pass@%s/nova_api", OPENSTACK_HOST_SERVER),
);
"vnc" = dict(
    "vncserver_listen", MY_IP,
    "vncserver_proxyclient_address", MY_IP,
);
"neutron" = dict(
    "url", format('http://%s:9696', NEUTRON_HOST_SERVER),
    "auth_url", format('http://%s:35357', NEUTRON_HOST_SERVER),
    "username", "neutron",
    "password", "neutron_good_password",
    "service_metadata_proxy", true,
    "metadata_proxy_shared_secret", "metadata_good_password",
);

# Manila section

include 'components/openstack/identity/gather/share/manila';
prefix "/software/components/openstack/share/manila";
"DEFAULT" = dict(
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
    "auth_strategy", "keystone",
    "default_share_type", "cephfsnative",
    "api_paste_config", "/etc/manila/api-paste.ini",
    "rootwrap_config", "/etc/manila/rootwrap.conf",
    "share_name_template", "share-%s",
    "my_ip", MY_IP,
    "enabled_share_protocols", list('NFS', 'CEPHFS'),
    "enabled_share_backends", list('lvm', 'cephfsnative'),
);
"database" = dict(
    "connection", format("mysql+pymysql://manila:manila_db_pass@%s/manila", OPENSTACK_HOST_SERVER),
);
"keystone_authtoken" = dict(
    "auth_uri", format('http://%s:5000', OPENSTACK_HOST_SERVER),
    "auth_url", format('http://%s:35357', OPENSTACK_HOST_SERVER),
    "username", "manila",
    "password", "manila_good_password",
    "memcached_servers", list('controller.mysite.com:11211'),
);
"oslo_concurrency" = dict(
    "lock_path", "/var/lib/manila/tmp",
);
# LVM storage setup
"lvm" = dict(
    "share_backend_name", "LVM",
    "share_driver", "manila.share.drivers.lvm.LVMShareDriver",
    "lvm_share_export_ip", MY_IP,
);
# Ceph backend setup
"cephfsnative" = dict(
    "share_backend_name", "cephfsnative",
    "share_driver", "manila.share.drivers.cephfs.driver.CephFSDriver",
);

# Heat section

include 'components/openstack/identity/gather/orchestration/heat';
prefix "/software/components/openstack/orchestration/heat";
"DEFAULT" = dict(
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
    "heat_metadata_server_url", format("http://%s:8000", OPENSTACK_HOST_SERVER),
    "heat_waitcondition_server_url", format("http://%s:8000/v1/waitcondition", OPENSTACK_HOST_SERVER),
    "stack_domain_admin", "heat_domain_admin",
    "stack_domain_admin_password", "heat_admin_good_password",
);
"database" = dict(
    "connection", format("mysql+pymysql://heat:heat_db_pass@%s/heat", OPENSTACK_HOST_SERVER),
);
"keystone_authtoken" = dict(
    "auth_uri", AUTH_URI,
    "auth_url", AUTH_URL,
    "username", "heat",
    "password", "heat_good_password",
    "memcached_servers", list(format("%s:11211", OPENSTACK_HOST_SERVER)),
);
"trustee" = dict(
    "username", "heat",
    "password", "heat_good_password",
    "auth_url", AUTH_URL,
);
"clients_keystone" = dict(
    "auth_uri", AUTH_URI,
);
"oslo_messaging_notifications" = dict(
    "driver", "messagingv2",
);

# Murano section

include 'components/openstack/identity/gather/catalog/murano';
prefix "/software/components/openstack/catalog/murano";
"DEFAULT" = dict(
    "debug", true,
);
"database" = dict(
    "connection", format("mysql+pymysql://murano:murano_db_pass@%s/murano", OPENSTACK_HOST_SERVER),
);
"keystone_authtoken" = dict(
    "auth_uri", AUTH_URI,
    "auth_url", AUTH_URL,
    "username", "murano",
    "password", "murano_good_password",
    "memcached_servers", list(format("%s:11211", OPENSTACK_HOST_SERVER)),
    "admin_password", "murano_good_password",
    "identity_uri", AUTH_URL,
);
"rabbitmq" = dict(
    "host", OPENSTACK_HOST_SERVER,
    "password", "rabbit_pass",
);
"murano" = dict(
    "url", format("http://%s:8082", OPENSTACK_HOST_SERVER),
);
"networking" = dict();

# OpenRC section

prefix "/software/components/openstack/openrc";
"os_username" = "admin";
"os_password" = "admingoodpass";
"os_region_name" = "RegionOne";
"os_auth_url" = format("http://%s:35357/v3", OPENSTACK_HOST_SERVER);

# RabbitMQ section
prefix "/software/components/openstack/messaging/rabbitmq";
"password" = "rabbit_pass";

# Ceilometer service section

include 'components/openstack/identity/gather/metric/ceilometer';
prefix "/software/components/openstack/metric/ceilometer/service";
"DEFAULT" = dict(
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
);
"service_credentials" = dict(
    "auth_url", format('http://%s:5000/v3', OPENSTACK_HOST_SERVER),
    "username", "ceilometer",
    "password", "ceilometer_good_password",
    "interface", "internalURL",
);

# Ceilometer Gnocchi section

prefix "/software/components/openstack/metric/ceilometer/gnocchi";
"api" = dict();
"keystone_authtoken" = dict(
    "auth_url", format('http://%s:5000/v3', OPENSTACK_HOST_SERVER),
    "username", "gnocchi",
    "password", "gnocchi_good_password",
    "interface", "internalURL",
);
"indexer" = dict(
    "url", format("mysql+pymysql://gnocchi:gnocchi_db_pass@%s/gnocchi", OPENSTACK_HOST_SERVER),
);
"storage" = dict(
    "file_basepath", "/var/lib/gnocchi",
);

# Cloudkitty section

include 'components/openstack/identity/gather/rating/cloudkitty';
prefix "/software/components/openstack/rating/cloudkitty";
"DEFAULT" = dict(
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
    "auth_strategy", "keystone",
);
"database" = dict(
    "connection", format("mysql+pymysql://cloudkitty:cloudkitty_db_pass@%s/cloudkitty", OPENSTACK_HOST_SERVER),
);
"keystone_authtoken" = dict(
    "auth_type", "password",
    "auth_uri", format('http://%s:5000', OPENSTACK_HOST_SERVER),
    "auth_url", format('http://%s:35357', OPENSTACK_HOST_SERVER),
    "username", "cloudkitty",
    "password", "cloudkitty_good_password",
    "memcached_servers", list('controller.mysite.com:11211'),
);
"collect" = dict();
"gnocchi_collector" = dict();
"keystone_fetcher" = dict(
    "keystone_version", 3,
);
"storage" = dict();
"tenant_fetcher" = dict();

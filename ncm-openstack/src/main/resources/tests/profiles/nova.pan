object template nova;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_nova_config;

"/metaconfig/module" = "openstack_common";

variable OPENSTACK_HOST_SERVER ?= 'controller.mysite.com';
variable NEUTRON_HOST_SERVER ?= 'neutron.mysite.com';
variable MY_IP ?= '10.0.1.2';

prefix "/metaconfig/contents";

"database" = dict(
    "connection", format("mysql+pymysql://nova:nova_db_pass@%s/nova", OPENSTACK_HOST_SERVER),
);
"DEFAULT" = dict(
    "auth_strategy", "keystone",
    "enabled_apis", list('osapi_compute', 'metadata'),
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
    "my_ip", MY_IP,
    "rootwrap_config", "/etc/nova/rootwrap.conf",
);
"api_database" = dict(
    "connection", format("mysql+pymysql://nova:nova_db_pass@%s/nova_api", OPENSTACK_HOST_SERVER),
);
"keystone_authtoken" = dict(
    "auth_uri", format('http://%s:5000', OPENSTACK_HOST_SERVER),
    "auth_url", format('http://%s:35357', OPENSTACK_HOST_SERVER),
    "username", "nova",
    "password", "nova_good_password",
    "memcached_servers", list('controller.mysite.com:11211'),
);
"vnc" = dict(
    "vncserver_listen", MY_IP,
    "vncserver_proxyclient_address", MY_IP,
);
"glance" = dict(
    "api_servers", list(format('http://%s:9292', OPENSTACK_HOST_SERVER)),
);
"oslo_concurrency" = dict(
    "lock_path", "/var/lib/nova/tmp",
);
"placement" = dict(
    "auth_url", format('http://%s:35357/v3', OPENSTACK_HOST_SERVER),
    "username", "placement",
    "password", "placement_good_password",
);
"neutron" = dict(
    "url", format('http://%s:9696', NEUTRON_HOST_SERVER),
    "auth_url", format('http://%s:35357', NEUTRON_HOST_SERVER),
    "username", "neutron",
    "password", "neutron_good_password",
    "service_metadata_proxy", true,
    "metadata_proxy_shared_secret", "metadata_good_password",
);

object template neutron;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_neutron_config;

"/metaconfig/module" = "common";

variable OPENSTACK_HOST_SERVER ?= 'controller.mysite.com';

prefix "/metaconfig/contents";

"database" = dict(
    "connection", format("mysql+pymysql://neutron:neutron_db_pass@%s/neutron", OPENSTACK_HOST_SERVER),
);
"DEFAULT" = dict(
    "auth_strategy", "keystone",
    "core_plugin", "ml2",
    "service_plugins", list('router'),
    "allow_overlapping_ips", true,
    "notify_nova_on_port_status_changes", true,
    "notify_nova_on_port_data_changes", true,
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
);
"keystone_authtoken" = dict(
    "auth_uri", format('http://%s:5000', OPENSTACK_HOST_SERVER),
    "auth_url", format('http://%s:35357', OPENSTACK_HOST_SERVER),
    "username", "neutron",
    "password", "neutron_good_password",
    "memcached_servers", list('controller.mysite.com:11211'),
);
"nova" = dict(
    "auth_url", format('http://%s:35357', OPENSTACK_HOST_SERVER),
    "username", "nova",
    "password", "nova_good_password",
);
"oslo_concurrency" = dict(
    "lock_path", "/var/lib/neutron/tmp",
);

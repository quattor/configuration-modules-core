object template nova_compute;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_nova_compute_config;

"/metaconfig/module" = "common";

variable OPENSTACK_HOST_SERVER ?= 'controller.mysite.com';
variable NEUTRON_HOST_SERVER ?= 'neutron.mysite.com';
variable MY_IP ?= '10.0.1.3';

prefix "/metaconfig/contents";

"DEFAULT" = dict(
    "auth_strategy", "keystone",
    "enabled_apis", list('osapi_compute', 'metadata'),
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
    "my_ip", MY_IP,
    "rootwrap_config", "/etc/nova/rootwrap.conf",
);
"keystone_authtoken" = dict(
    "auth_uri", format('http://%s:5000', OPENSTACK_HOST_SERVER),
    "auth_url", format('http://%s:35357', OPENSTACK_HOST_SERVER),
    "username", "nova",
    "password", "nova_good_password",
    "memcached_servers", list('controller.mysite.com:11211'),
);
"vnc" = dict(
    "enabled", true,
    "vncserver_listen", "0.0.0.0",
    "vncserver_proxyclient_address", MY_IP,
    "novncproxy_base_url", format('http://%s:6080/vnc_auto.html', OPENSTACK_HOST_SERVER),
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
"libvirt" = dict(
    "virt_type", "kvm",
);
"neutron" = dict(
    "url", format('http://%s:9696', NEUTRON_HOST_SERVER),
    "auth_url", format('http://%s:35357', NEUTRON_HOST_SERVER),
    "username", "neutron",
    "password", "neutron_good_password",
);

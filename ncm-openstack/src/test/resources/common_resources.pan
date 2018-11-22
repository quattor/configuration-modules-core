template common_resources;

# mock pkg_repl first
function pkg_repl = { null; };
include 'components/openstack/config';
'/software/components/openstack/dependencies' = null;
'/software/components/sudo/dependencies' = null;

variable OPENSTACK_HOST_SERVER ?= 'controller.mysite.com';
variable NEUTRON_HOST_SERVER ?= 'neutron.mysite.com';
variable MY_IP ?= '10.0.1.2';
variable AUTH_URL ?= format('http://%s:35357', OPENSTACK_HOST_SERVER);
variable AUTH_URI ?= format('http://%s:5000', OPENSTACK_HOST_SERVER);


# Hardware section

prefix "/system/network";
"domainname" = "mysite.com";
"hostname" = "controller";


# Nova/Compute section

prefix "/software/components/openstack/compute/nova";
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
);

# Neutron section

prefix "/software/components/openstack/network/neutron/service";
"DEFAULT" = dict(
    "auth_strategy", "keystone",
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
);
"keystone_authtoken" = dict(
    "auth_uri", format('http://%s:5000', OPENSTACK_HOST_SERVER),
    "auth_url", format('http://%s:35357', OPENSTACK_HOST_SERVER),
    "username", "neutron",
    "password", "neutron_good_password",
    "memcached_servers", list('controller.mysite.com:11211'),
);
"oslo_concurrency" = dict(
    "lock_path", "/var/lib/neutron/tmp",
);

# Neutron/Linuxbridge section

prefix "/software/components/openstack/network/neutron/linuxbridge";
"linux_bridge" = dict(
    "physical_interface_mappings", list('provider:eth1'),
);
"vxlan" = dict(
    "enable_vxlan", true,
    "local_ip", MY_IP,
    "l2_population", true,
);
"securitygroup" = dict(
    "enable_security_group", true,
    "firewall_driver", "neutron.agent.linux.iptables_firewall.IptablesFirewallDriver",
);

# Cinder section

prefix "/software/components/openstack/volume/cinder";
"DEFAULT" = dict(
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
    "auth_strategy", "keystone",
    "enabled_backends", list('ceph', 'lvm'),
    "my_ip", MY_IP,
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

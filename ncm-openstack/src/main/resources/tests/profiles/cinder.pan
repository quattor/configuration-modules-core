object template cinder;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_cinder_config;

"/metaconfig/module" = "common";

variable OPENSTACK_HOST_SERVER ?= 'controller.mysite.com';
variable MY_IP ?= '10.0.1.2';

prefix "/metaconfig/contents";
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

include 'components/openstack/identity/gather/volume/cinder';
"quattor" = value("/software/components/openstack/volume/cinder/quattor");
"/software" = null;

object template manila;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_manila_config;

"/metaconfig/module" = "common";

variable OPENSTACK_HOST_SERVER ?= 'controller.mysite.com';
variable MY_IP ?= '10.0.1.2';

prefix "/metaconfig/contents";
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

include 'components/openstack/identity/gather/share/manila';
"quattor" = value("/software/components/openstack/share/manila/quattor");
"/software" = null;

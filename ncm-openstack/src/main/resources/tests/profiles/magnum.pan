object template magnum;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_magnum_config;

"/metaconfig/module" = "common";

variable OPENSTACK_HOST_SERVER ?= 'controller.mysite.com';
variable AUTH_URL ?= format('http://%s:35357', OPENSTACK_HOST_SERVER);
variable AUTH_URI ?= format('http://%s:5000/v3', OPENSTACK_HOST_SERVER);
variable MY_IP ?= '10.0.1.10';


prefix "/metaconfig/contents";
"DEFAULT" = dict(
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
);
"database" = dict(
    "connection", format("mysql+pymysql://magnum:magnum_db_pass@%s/magnum", OPENSTACK_HOST_SERVER),
);
"keystone_authtoken" = dict(
    "auth_uri", AUTH_URI,
    "auth_url", AUTH_URL,
    "username", "magnum",
    "password", "magnum_good_password",
    "memcached_servers", list(format("%s:11211", OPENSTACK_HOST_SERVER)),
);
"trust" = dict(
    "trustee_domain_admin_password", "magnum_domain_good_password",
);
"api" = dict(
    "host", MY_IP,
);
"oslo_concurrency" = dict(
    "lock_path", "/var/lib/magnum/tmp",
);
"oslo_messaging_notifications" = dict(
    "driver", "messagingv2",
);

include 'components/openstack/identity/gather/container-infra/magnum';
"quattor" = value("/software/components/openstack/container-infra/magnum/quattor");
"/software" = null;

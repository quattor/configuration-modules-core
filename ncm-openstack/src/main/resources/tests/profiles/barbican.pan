object template barbican;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_barbican_config;

"/metaconfig/module" = "common";

variable OPENSTACK_HOST_SERVER ?= 'controller.mysite.com';
variable AUTH_URL ?= format('http://%s:35357', OPENSTACK_HOST_SERVER);
variable AUTH_URI ?= format('http://%s:5000/v3', OPENSTACK_HOST_SERVER);


prefix "/metaconfig/contents";
"DEFAULT" = dict(
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
    "sql_connection", format("mysql+pymysql://barbican:barbican_db_pass@%s/barbican", OPENSTACK_HOST_SERVER),
);
"keystone_authtoken" = dict(
    "auth_uri", AUTH_URI,
    "auth_url", AUTH_URL,
    "username", "barbican",
    "password", "barbican_good_password",
    "memcached_servers", list(format("%s:11211", OPENSTACK_HOST_SERVER)),
);


include 'components/openstack/identity/gather/key-manager/barbican';
"quattor" = value("/software/components/openstack/key-manager/barbican/quattor");
"/software" = null;

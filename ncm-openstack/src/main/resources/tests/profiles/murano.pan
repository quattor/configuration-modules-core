object template murano;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_murano_config;

"/metaconfig/module" = "common";

variable OPENSTACK_HOST_SERVER ?= 'controller.mysite.com';
variable AUTH_URL ?= format('http://%s:35357', OPENSTACK_HOST_SERVER);
variable AUTH_URI ?= format('http://%s:5000', OPENSTACK_HOST_SERVER);

prefix "/metaconfig/contents";
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

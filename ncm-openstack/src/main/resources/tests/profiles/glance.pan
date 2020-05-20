object template glance;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_glance_service_config;

"/metaconfig/module" = "common";

variable OPENSTACK_HOST_SERVER ?= 'controller.mysite.com';

prefix "/metaconfig/contents";
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
"cors" = dict(
    "allowed_origin", list('https://dashboard.example.com', 'http://localhost'),
);

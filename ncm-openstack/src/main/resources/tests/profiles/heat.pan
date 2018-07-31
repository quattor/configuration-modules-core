object template heat;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_heat_config;

"/metaconfig/module" = "common";

variable OPENSTACK_HOST_SERVER ?= 'controller.mysite.com';
variable AUTH_URL ?= format('http://%s:35357', OPENSTACK_HOST_SERVER);
variable AUTH_URI ?= format('http://%s:5000', OPENSTACK_HOST_SERVER);

prefix "/metaconfig/contents";

"DEFAULT" = dict(
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
    "heat_metadata_server_url", format("http://%s:8000", OPENSTACK_HOST_SERVER),
    "heat_waitcondition_server_url", format("http://%s:8000/v1/waitcondition", OPENSTACK_HOST_SERVER),
    "stack_domain_admin", "heat_domain_admin",
    "stack_domain_admin_password", "heat_admin_good_password",
);
"database" = dict(
    "connection", format("mysql+pymysql://heat:heat_db_pass@%s/heat", OPENSTACK_HOST_SERVER),
);
"keystone_authtoken" = dict(
    "auth_uri", AUTH_URI,
    "auth_url", AUTH_URL,
    "username", "heat",
    "password", "heat_good_password",
    "memcached_servers", list(format("%s:11211", OPENSTACK_HOST_SERVER)),
);
"trustee" = dict(
    "username", "heat",
    "password", "heat_good_password",
    "auth_url", AUTH_URL,
);
"clients_keystone" = dict(
    "auth_uri", AUTH_URI,
);

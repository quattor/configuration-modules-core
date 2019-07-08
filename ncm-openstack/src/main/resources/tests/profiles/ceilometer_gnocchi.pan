object template ceilometer_gnocchi;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_ceilometer_gnocchi_config;

"/metaconfig/module" = "common";

variable OPENSTACK_HOST_SERVER ?= 'controller.mysite.com';

prefix "/metaconfig/contents";

"api" = dict();
"keystone_authtoken" = dict(
    "auth_url", format('http://%s:5000/v3', OPENSTACK_HOST_SERVER),
    "username", "gnocchi",
    "password", "gnocchi_good_password",
    "interface", "internalURL",
);
"indexer" = dict(
    "url", format("mysql+pymysql://gnocchi:gnocchi_db_pass@%s/gnocchi", OPENSTACK_HOST_SERVER),
);


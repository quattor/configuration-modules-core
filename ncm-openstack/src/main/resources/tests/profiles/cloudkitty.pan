object template cloudkitty;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_cloudkitty_config;

"/metaconfig/module" = "common";

variable OPENSTACK_HOST_SERVER ?= 'controller.mysite.com';

prefix "/metaconfig/contents";
"DEFAULT" = dict(
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
    "auth_strategy", "keystone",
);
"collect" = dict(
    "metrics_conf", "/etc/cloudkitty/my_fancy_metrics.yml",
);
"gnocchi_collector" = dict(
    "auth_section", "keystone_authtoken",
);
"keystone_authtoken" = dict(
    "auth_type", "password",
    "auth_uri", format('http://%s:5000', OPENSTACK_HOST_SERVER),
    "auth_url", format('http://%s:35357', OPENSTACK_HOST_SERVER),
    "username", "cloudkitty",
    "password", "cloudkitty_good_password",
    "memcached_servers", list('controller.mysite.com:11211'),
);
"keystone_fetcher" = dict(
    "keystone_version", 3,
);
"storage" = dict(
    "backend", "sqlalchemy",
);
"tenant_fetcher" = dict(
    "backend", "keystone",
);
"database" = dict(
    "connection", format("mysql+pymysql://cloudkitty:cloudkitty_db_pass@%s/cloudkitty", OPENSTACK_HOST_SERVER),
);

include 'components/openstack/identity/gather/rating/cloudkitty';
"quattor" = value("/software/components/openstack/rating/cloudkitty/quattor");
"/software" = null;

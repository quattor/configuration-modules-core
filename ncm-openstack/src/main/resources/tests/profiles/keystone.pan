object template keystone;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_keystone_config;

"/metaconfig/module" = "common";

prefix "/metaconfig/contents";
"database" = dict(
    "connection", "mysql+pymysql://keystone:keystone_db_pass@controller.mysite.com/keystone",
);

include 'components/openstack/identity/gather/identity/keystone';
"quattor" = value("/software/components/openstack/identity/keystone/quattor");
"/software" = null;

object template keystone;

include 'components/openstack/schema';

bind "/metaconfig/contents/keystone" = openstack_keystone_config;

"/metaconfig/module" = "openstack_common";

prefix "/metaconfig/contents/keystone";
"database" = dict(
    "connection", "mysql+pymysql://keystone:keystone_db_pass@controller.mysite.com/keystone",
);

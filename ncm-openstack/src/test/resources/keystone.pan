unique template keystone;

include 'components/openstack/config';

prefix "/software/components/openstack/keystone";
"database" = dict(
    "connection", "mysql+pymysql://keystone:keystone_db_pass@controller.mysite.com/keystone",
);

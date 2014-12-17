object template oned_config;

include 'metaconfig/opennebula/oned';

prefix "/software/components/metaconfig/services/{/etc/one/oned.conf}/contents/oned";
"db" = nlist(
    "backend", "mysql",
    "server", "localhost",
    "port", 0,
    "user", "oneadmin",
    "passwd", "my-fancy-pass",
    "db_name", "opennebula",
);
"default_device_prefix" = "vd";
"onegate_endpoint" = "http://hyp004.cubone.os:5030";

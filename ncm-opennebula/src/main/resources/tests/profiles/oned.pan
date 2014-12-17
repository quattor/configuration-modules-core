object template oned;

include 'metaconfig/opennebula/schema';

bind "/metaconfig/contents/oned" = opennebula_oned;

"/metaconfig/module" = "opennebula/oned";

prefix "/metaconfig/contents/oned";
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

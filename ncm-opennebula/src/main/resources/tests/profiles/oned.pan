object template oned;

include 'components/opennebula/schema';

bind "/metaconfig/contents/oned" = opennebula_oned;

"/metaconfig/module" = "oned";

prefix "/metaconfig/contents/oned";
"db" = dict(
    "backend", "mysql",
    "server", "localhost",
    "port", 0,
    "user", "oneadmin",
    "passwd", "my-fancy-pass",
    "db_name", "opennebula",
);
"raft_leader_hook" = dict(
    "arguments", "leader ens1 10.0.0.2/24",
);
"raft_follower_hook" = dict(
    "arguments", "follower ens1 10.0.0.2/24",
);
"log" = dict(
    "system", "syslog",
    "debug_level", 3,
);
"quota_vm_attribute" = list("GPU_L40", "GPU_A20");
"default_device_prefix" = "vd";
"onegate_endpoint" = "http://hyp004.cubone.os:5030";

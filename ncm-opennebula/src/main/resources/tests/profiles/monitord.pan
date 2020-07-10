object template monitord;

include 'components/opennebula/schema';

bind "/metaconfig/contents/monitord" = opennebula_monitord;

"/metaconfig/module" = "monitord";

prefix "/metaconfig/contents/monitord";
"db" = dict(
    "connections", 10,
);
"log" = dict(
    "system", "syslog",
    "debug_level", 5,
);
"network" = dict(
    "address", "192.168.0.2",
);
"probes_period" = dict();

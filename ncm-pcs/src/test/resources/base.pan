unique template base;

function pkg_repl = { null; };
include 'components/pcs/config';
"/software/components/pcs/dependencies/pre" = null;

prefix "/software/components/pcs/cluster";
"name" = "simple";
"nodes" = list("nodea.domain", "nodeb.domain");
"internal" = list("nodea.private", "nodeb.private");

prefix "/software/components/pcs/default";
"resource/migration-threshold" = 20;
"resource/resource-stickiness" = 10;
"resource_op/timeout" = 10;

prefix "/software/components/pcs/resource/magicip";
"standard" = "ocf";
"provider" = "heartbeat";
"type" = "IPaddr2";
"option/ip" = "1.2.3.4";
"option/cidr_netmask" = "32";
"option/nic" = "eth0";
"operation/monitor/interval" = 30;
"operation/monitor_master" = dict(
    "name", "monitor",
    "interval", 27,
    "role", "Master",
    "record-pending", false,
    );

prefix "/software/components/pcs/resource/mastermagic";
"standard" = null;
"provider" = null;
"type" = "master";
"master/resource" = "magicip";
"option/notify" = "true";

prefix "/software/components/pcs/stonith/fence_nodea";
"type" = "fence_magic";
"option/ip" = "1.2.3.4";
"option/user" = "magic";
"operation/start/timeout" = "60s";
"operation/stop/timeout" = "60s";
"group" = "test";
"before" = "something";
"after" = "else";
"disabled" = true;

prefix "/software/components/pcs/constraint/colocation/0";
"source/name" = "src";
"source/master" = true;
"target/name" = "tgt";
"target/master" = false;
"score" = "-INFINITY";
"options/opt1" = "5";

prefix "/software/components/pcs/constraint/location/avoids/magicip";
"nodea" = "INFINITY";
"nodeb" = "-INFINITY";

prefix "/software/components/pcs/constraint/order/0";
"source/name" = "src";
"source/action" = "promote";
"target/name" = "tgt";
"target/action" = "start";
"options/symmetrical" = "false";
"options/kind" = "Mandatory";

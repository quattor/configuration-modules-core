object template vnet_br101;

include 'metaconfig/opennebula/schema';

bind "/metaconfig/contents/vnet" = opennebula_vnet;

"/metaconfig/module" = "opennebula/vnet";

prefix "/metaconfig/contents/vnet";
"name" = "node2.cubone.os";
"type" = "FIXED";
"bridge" = "br101";
"gateway" = "10.141.10.250";
"dns" = "10.141.10.250";
"network_mask" = "255.255.0.0";

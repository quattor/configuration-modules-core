object template ipv6;

include 'pan/types';
include 'components/network/core-schema';

bind "/system/network" = structure_network;

"/system/network" = create("defaultnetwork");
"/system/network/interfaces/eth0" = create("defaultinterface");

prefix "/system/network";
"interfaces/eth0/defroute" = true;
"interfaces/eth0/ipv6_defroute" = false;
"interfaces/eth0/ipv6addr" = "2001:678:123:e012::45/64";
"interfaces/eth0/ipv6addr_secondaries" = list("2001:678:123:e012::46/64", "2001:678:123:e012::47/64");
"interfaces/eth0/ipv6_autoconf" = false; # boolean
"ipv6/default_gateway" = "2001:678:123:e012::2";
"ipv6/gatewaydev" = "eth0";
"ipv6/enabled" = true;

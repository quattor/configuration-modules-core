object template bridge;

include 'pan/types';
include 'components/network/core-schema';

bind "/system/network" = structure_network;


"/system/network" = create("defaultnetwork");
"/system/network/interfaces/br0" = create("defaultinterface");

prefix "/system/network/interfaces/br0";

"delay" = 5;
"stp" = true;
"bridging_opts/hairpin_mode" = 5;



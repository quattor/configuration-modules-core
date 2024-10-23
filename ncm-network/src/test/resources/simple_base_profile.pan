template simple_base_profile;

function pkg_repl = { null; };
include 'components/network/config';
'/software/components/network/dependencies' = null;

include 'pan/types';
include 'components/network/core-schema';

bind "/system/network" = structure_network;

"/system/network" = create("defaultnetwork");
"/system/network/interfaces/eth0" = create("defaultinterface");

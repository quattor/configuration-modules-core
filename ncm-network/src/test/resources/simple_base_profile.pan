template simple_base_profile;

# uncomment to test any schema changes
#variable QUATTOR_TYPES_NETWORK_LEGACY = false;
#variable QUATTOR_TYPES_NETWORK_BACKEND = 'nmstate';

function pkg_repl = { null; };
include 'components/network/config';
'/software/components/network/dependencies' = null;

include 'pan/types';
include 'components/network/core-schema';

bind "/system/network" = structure_network;

"/system/network" = create("defaultnetwork");
"/system/network/interfaces/eth0" = create("defaultinterface");

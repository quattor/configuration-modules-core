object template nmstate_bridge;

variable QUATTOR_TYPES_NETWORK_BACKEND = 'nmstate';

include 'simple_base_profile';
include 'components/network/config-nmstate';

"/hardware/cards/nic/eth0/hwaddr" = "6e:a5:1b:55:77:0a";

# bridge device keeps IP/default route
"/system/network/interfaces/br0" = create("defaultinterface");
prefix "/system/network/interfaces/br0";
"type" = "Bridge";
"stp" = true;
"delay" = 5;

# bridge port carries no IP/routes
prefix "/system/network/interfaces/eth0";
"bridge" = "br0";
"bootproto" = "none";
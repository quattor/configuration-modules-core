object template nmstate_route_rule;

variable QUATTOR_TYPES_NETWORK_BACKEND = 'nmstate';

include 'simple_base_profile';
include 'components/network/config-nmstate';


# test for nmstate rule parameters on new interface
"/hardware/cards/nic/eth0/hwaddr" = "6e:a5:1b:55:77:0a";

prefix "/system/network/interfaces/eth0";
"route/0" = dict(
    "address", "1.2.3.9",
    "type", "blackhole"
);

prefix "/system/network/interfaces/eth0";
"rule/0" = dict(
    "to", "1.2.3.4/24",
    "action", "unreachable",
    "iif", "eth0",
    "fwmask", "000",
    "fwmark", "111",
);
"rule/1" = dict(
    "to", "1.2.4.4/24",
    "action", "prohibit",
    "state", "absent",
);

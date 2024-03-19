object template nmstate_route_rule;

include 'simple_base_profile';
include 'components/network/config-nmstate';

# test for nmstate rule parameters on new interface
"/hardware/cards/nic/eth0/hwaddr" = "6e:a5:1b:55:77:0a";
prefix "/system/network/interfaces/eth0";
"rule/0" = dict("to", "1.2.3.4/24", "nmstate-action", "unreachable",
            "nmstate-iif", "eth0", "nmstate-fwmask", "000", "nmstate-fwmark", "111");
"rule/1" = dict("to", "1.2.4.4/24", "nmstate-action", "prohibit", "nmstate-state", "absent");
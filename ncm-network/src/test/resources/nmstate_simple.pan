object template nmstate_simple;

variable QUATTOR_TYPES_NETWORK_BACKEND = 'nmstate';

include 'simple_base_profile';
"/hardware/cards/nic/eth0/hwaddr" = "6e:a5:1b:55:77:0a";

"/system/network/device_config/keep-configuration" = "no";
# the next include is mainly to the profile, it is not used in the tests
#   (unless the component gets specific schema things)
include 'components/network/config-nmstate';

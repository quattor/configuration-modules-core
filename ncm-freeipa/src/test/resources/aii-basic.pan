object template aii-basic;

include 'base';

final variable FREEIPA_AII_DNS = true;
final variable FREEIPA_AII_DISABLE = true;

include 'quattor/aii/freeipa/default';

prefix "/hardware/cards/nic";
"eth0/boot" = false;
"eth1/boot" = true;

prefix "/system/network/interfaces";
"eth0/ip" = "1.2.3.4";
"eth1/ip" = "5.6.7.8";

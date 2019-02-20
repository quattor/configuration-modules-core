object template simple;

include 'simple_base_profile';

prefix "/system/network/interfaces/eth0/ethtool";
"wol" = "b";
"speed" = 10000;
"autoneg" = 'on';
prefix "channels";
"other" = 1;
"combined" = 7;

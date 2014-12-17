object template network_config;

prefix "/hardware/cards/nic";
"eth0/hwaddr" = "00:11:22:33:44:55";
"em3/hwaddr" = "00:11:22:33:44:66";

include 'metaconfig/udev/network_config';

prefix "/software/components/metaconfig/services/{/etc/udev/rules.d/09-network.rules}/contents";
"interfaces" = udev_all_interfaces();

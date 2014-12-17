object template public_addresses;

include 'metaconfig/ctdb/public_addresses';

'/system/network/interfaces/vlan0/device' = 'eth0';

prefix "/software/components/metaconfig/services/{/etc/ctdb/public_addresses}/contents";
"addresses/0/network_name" = "172.24.14.195/16";
"addresses/0/network_interface" = "eth0";
"addresses/1/network_name" = "172.24.14.196/16";
"addresses/1/network_interface" = "eth0";
"addresses/2/network_name" = "172.24.14.197/16";
"addresses/2/network_interface" = "eth0";

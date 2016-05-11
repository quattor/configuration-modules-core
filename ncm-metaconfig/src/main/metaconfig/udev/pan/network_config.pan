unique template metaconfig/udev/network_config;

include 'metaconfig/udev/schema';

prefix "/software/components/metaconfig/services/{/etc/udev/rules.d/09-network.rules}";

"mode" = 0644;
"owner" = "root";
"group" = "root";
"module" = "udev/ethnames";

bind "/software/components/metaconfig/services/{/etc/udev/rules.d/09-network.rules}/contents/interfaces" = udev_interfaces;

function udev_all_interfaces = {
    t=nlist();
    foreach (iface; v; value("/hardware/cards/nic")) {
        t[iface] = v["hwaddr"];
    };
    t;
};

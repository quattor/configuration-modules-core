declaration template metaconfig/udev/schema;

type udev_interfaces = nlist with {
    foreach(intf;macaddr;SELF) {
        intf_path = format("/hardware/cards/nic/%s", intf);
        mac_path = format("%s/hwaddr", intf_path);
        if (! (exists(intf_path) && exists(mac_path) && value(mac_path) == macaddr)) {
            return(false);
        }; 
    };
    return(true);
};

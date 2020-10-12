declaration template metaconfig/udev/schema;

type udev_interfaces = dict with {
    foreach(intf; macaddr; SELF) {
        intf_path = format("/hardware/cards/nic/%s", intf);
        mac_path = format("%s/hwaddr", intf_path);
        if (! (exists(intf_path) && exists(mac_path) && value(mac_path) == macaddr)) {
            return(false);
        };
    };
    return(true);
};

type udev_scsi_run = string[];
type udev_dm_run = string[];
type udev_nvme_run = string[];

type udev_action_attr = {
    'action' : string
    'subsystem' : string
    'attributes' : string{}
};

type udev_action_attrs = udev_action_attr[];

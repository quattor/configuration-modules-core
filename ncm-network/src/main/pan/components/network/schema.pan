# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/network/schema;

include 'quattor/schema';


type component_network_type = {
    include structure_component
    # Name of the auto-generated udev rule which needs to be removed to allow udev re-consider the interface names
    "udev_rules_file" ? string
    # E.g. "/usr/bin/udevadm trigger", although restricting the scope to just network devices should not hurt
    "udev_trigger_command" ? string
    # E.g. "/usr/bin/udevadm settle"
    "udev_settle_command" ? string
};


bind "/software/components/network" = component_network_type;

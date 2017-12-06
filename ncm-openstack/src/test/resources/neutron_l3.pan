template neutron_l3;

include 'components/openstack/config';

prefix "/software/components/openstack/neutron_l3";

"DEFAULT" = dict(
    "interface_driver", "linuxbridge",
);

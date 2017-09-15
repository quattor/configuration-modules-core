object template neutron_l3;

include 'components/openstack/schema';

bind "/metaconfig/contents/neutron_l3" = openstack_neutron_l3_config;

"/metaconfig/module" = "openstack_common";

prefix "/metaconfig/contents/neutron_l3";

"DEFAULT" = dict(
    "interface_driver", "linuxbridge",
);

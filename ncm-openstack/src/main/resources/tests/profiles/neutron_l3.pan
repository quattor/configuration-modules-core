object template neutron_l3;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_neutron_l3_config;

"/metaconfig/module" = "common";

prefix "/metaconfig/contents";

"DEFAULT" = dict(
    "interface_driver", "linuxbridge",
);

object template neutron_openvswitch;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_neutron_openvswitch_config;

"/metaconfig/module" = "common";

prefix "/metaconfig/contents";

"ovs" = dict(
    "local_ip", "10.0.1.4",
);
"agent" = dict(
    "l2_population", true,
);
"securitygroup" = dict(
    "firewall_driver", "openvswitch",
);

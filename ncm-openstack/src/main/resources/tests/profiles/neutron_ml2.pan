object template neutron_ml2;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_neutron_ml2_config;

"/metaconfig/module" = "common";

prefix "/metaconfig/contents";
"ml2_type_flat" = dict();

"ml2_type_vxlan" = dict(
    'vni_ranges', '1:1000',
);
"securitygroup" = dict(
    "enable_security_group", true,
    "firewall_driver", "neutron.agent.linux.iptables_firewall.IptablesFirewallDriver",
);

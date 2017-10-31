object template neutron_linuxbridge;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_neutron_linuxbridge_config;

"/metaconfig/module" = "openstack_common";

prefix "/metaconfig/contents";

"linux_bridge" = dict(
    "physical_interface_mappings", list('provider:eth1'),
);
"vxlan" = dict(
    "enable_vxlan", true,
    "local_ip", "10.0.1.4",
    "l2_population", true,
);
"securitygroup" = dict(
    "enable_security_group", true,
    "firewall_driver", "neutron.agent.linux.iptables_firewall.IptablesFirewallDriver",
);

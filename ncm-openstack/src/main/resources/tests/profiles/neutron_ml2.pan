object template neutron_ml2;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_neutron_ml2_config;

"/metaconfig/module" = "common";

prefix "/metaconfig/contents";

"securitygroup" = dict(
    "enable_security_group", true,
    "firewall_driver", "neutron.agent.linux.iptables_firewall.IptablesFirewallDriver",
);

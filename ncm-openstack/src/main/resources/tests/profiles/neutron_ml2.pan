object template neutron_ml2;

include 'components/openstack/schema';

bind "/metaconfig/contents/neutron_ml2" = openstack_neutron_ml2_config;

"/metaconfig/module" = "openstack_common";

prefix "/metaconfig/contents/neutron_ml2";

"securitygroup" = dict(
    "enable_security_group", true,
    "firewall_driver", "neutron.agent.linux.iptables_firewall.IptablesFirewallDriver",
);

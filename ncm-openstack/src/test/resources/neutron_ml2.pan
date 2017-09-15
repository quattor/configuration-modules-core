template neutron_ml2;

include 'components/openstack/config';

prefix "/software/components/openstack/neutron_ml2";

"securitygroup" = dict(
    "enable_security_group", true,
    "firewall_driver", "neutron.agent.linux.iptables_firewall.IptablesFirewallDriver",
);

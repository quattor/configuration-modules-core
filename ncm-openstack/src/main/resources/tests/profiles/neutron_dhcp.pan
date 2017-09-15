object template neutron_dhcp;

include 'components/openstack/schema';

bind "/metaconfig/contents/neutron_dhcp" = openstack_neutron_dhcp_config;

"/metaconfig/module" = "openstack_common";

prefix "/metaconfig/contents/neutron_dhcp";

"DEFAULT" = dict(
    "interface_driver", "linuxbridge",
    "dhcp_driver", "neutron.agent.linux.dhcp.Dnsmasq",
    "enable_isolated_metadata", true,
);

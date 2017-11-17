object template neutron_dhcp;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_neutron_dhcp_config;

"/metaconfig/module" = "common";

prefix "/metaconfig/contents";

"DEFAULT" = dict(
    "interface_driver", "linuxbridge",
    "dhcp_driver", "neutron.agent.linux.dhcp.Dnsmasq",
    "enable_isolated_metadata", true,
);

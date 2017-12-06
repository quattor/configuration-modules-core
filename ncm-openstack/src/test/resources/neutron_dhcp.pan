template neutron_dhcp;

include 'components/openstack/config';

prefix "/software/components/openstack/neutron_dhcp";

"DEFAULT" = dict(
    "interface_driver", "linuxbridge",
    "dhcp_driver", "neutron.agent.linux.dhcp.Dnsmasq",
    "enable_isolated_metadata", true,
);

# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/openstack/network/neutron;

include 'components/openstack/identity';

@documentation {
    The Neutron configuration options in ml2_conf.ini "ml2" Section.
}
type openstack_neutron_ml2 = {
    @{WARNING: After you configure the ML2 plug-in,
    removing values in the type_drivers option can lead to database inconsistency}
    'type_drivers' : openstack_neutrondriver[] = list('flat', 'vlan', 'vxlan')
    @{Ordered list of network_types to allocate as tenant networks. The default
    value "local" is useful for single-box testing but provides no connectivity
    between hosts}
    'tenant_network_types' : openstack_neutrondriver[] = list('vxlan')
    @{An ordered list of networking mechanism driver entrypoints to be loaded from
    the neutron.ml2.mechanism_drivers namespace}
    'mechanism_drivers' : openstack_neutron_mechanism_drivers[] = list('linuxbridge', 'l2population')
    @{An ordered list of extension driver entrypoints to be loaded from the
    neutron.ml2.extension_drivers namespace}
    'extension_drivers' : openstack_neutronextension[] = list('port_security')
} = dict();

@documentation {
    The Neutron configuration options in ml2_conf.ini "ml2_type_flat" Section.
}
type openstack_neutron_ml2_type_flat = {
    @{List of physical_network names with which flat networks can be created. Use
    default "*" to allow flat networks with arbitrary physical_network names. Use
    an empty list to disable flat networks}
    'flat_networks' : string[] = list('provider')
} = dict();

@documentation {
    The Neutron configuration options in ml2_conf.ini "ml2_type_vxlan" Section.
}
type openstack_neutron_ml2_type_vxlan = {
    @{Configure the VXLAN network identifier range for self-service networks}
    'vni_ranges' : string = '1:1000'
} = dict();

@documentation {
    The Neutron configuration options in ml2_conf.ini "ml2_type_vlan" Section.
}
type openstack_neutron_ml2_type_vlan = {
    @{List of <physical_network>:<vlan_min>:<vlan_max> or <physical_network>
    specifying physical_network names usable for VLAN provider and tenant
    networks, as well as ranges of VLAN tags on each available for allocation to
    tenant networks}
    'network_vlan_ranges' : string[] = list('provider')
} = dict();

@documentation {
    The Neutron configuration options in ml2_conf.ini "securitygroup" Section.
}
type openstack_neutron_securitygroup = {
    @{Use ipset to speed-up the iptables based security groups. Enabling ipset
    support requires that ipset is installed on L2 agent node}
    'enable_ipset' ? boolean = true
    @{Controls whether the neutron security group API is enabled in the server. It
    should be false when using no security groups or using the nova security
    group API}
    'enable_security_group' ? boolean = true
    @{Driver for security groups}
    'firewall_driver' ? openstack_neutron_firewall_driver = 'neutron.agent.linux.iptables_firewall.IptablesFirewallDriver'
};

@documentation {
    The Neutron configuration options in linuxbridge_agent.ini "vxlan" Section.
}
type openstack_neutron_vxlan = {
    @{Enable VXLAN on the agent. Can be enabled when agent is managed by ml2 plugin
    using linuxbridge mechanism driver}
    'enable_vxlan' ? boolean = true
    @{IP address of local overlay (tunnel) network endpoint. Use either an IPv4 or
    IPv6 address that resides on one of the host network interfaces. The IP
    version of this value must match the value of the 'overlay_ip_version' option
    in the ML2 plug-in configuration file on the neutron server node(s)}
    'local_ip' : type_ip
    @{Extension to use alongside ml2 plugins l2population mechanism driver. It
    enables the plugin to populate VXLAN forwarding table}
    'l2_population' ? boolean = true
};

@documentation {
    The Neutron configuration options in linuxbridge_agent.ini "linux_bridge" Section.
}
type openstack_neutron_linux_bridge = {
    @{Comma-separated list of <physical_network>:<physical_interface> tuples
    mapping physical network names to the agents node-specific physical network
    interfaces to be used for flat and VLAN networks. All physical networks
    listed in network_vlan_ranges on the server should have mappings to
    appropriate interfaces on each agent.
    https://docs.openstack.org/ocata/install-guide-rdo/environment-networking.html}
    'physical_interface_mappings' : string[]
};

@documentation {
    The Neutron configuration options in openvswitch_agent.ini "ovs" Section.
}
type openstack_neutron_ovs = {
    include openstack_neutron_vxlan
    @{Comma-separated list of <physical_network>:<bridge> tuples mapping physical
    network names to the agents node-specific Open vSwitch bridge names to be
    used for flat and VLAN networks. The length of bridge names should be no more
    than 11. Each bridge must exist, and should have a physical network interface
    configured as a port. All physical networks configured on the server should
    have mappings to appropriate bridges on each agent. Note: If you remove a
    bridge from this mapping, make sure to disconnect it from the integration
    bridge as it wont be managed by the agent anymore}
    'bridge_mappings' : string[] = list('provider:br-provider')
};

@documentation {
    The Neutron configuration options in openvswitch_agent.ini "agent" Section.
}
type openstack_neutron_agent = {
    @{Extension to use alongside ml2 plugins l2population mechanism driver. It
    enables the plugin to populate VXLAN forwarding table}
    'l2_population' : boolean = true
    @{Network types supported by the agent (gre and/or vxlan)}
    'tunnel_types' : openstack_tunnel_types[] = list('vxlan')
};


@documentation {
    list of Neutron common configuration sections
}
type openstack_neutron_common = {
    'DEFAULT' : openstack_DEFAULTS
    'keystone_authtoken' : openstack_keystone_authtoken
    'oslo_concurrency' : openstack_oslo_concurrency
};

@documentation {
    list of Neutron ml2 service sections
};
type openstack_neutron_ml2_config = {
    'ml2' : openstack_neutron_ml2
    'ml2_type_flat' : openstack_neutron_ml2_type_flat
    'ml2_type_vxlan' ? openstack_neutron_ml2_type_vxlan
    'ml2_type_vlan' ? openstack_neutron_ml2_type_vlan
    'securitygroup' ? openstack_neutron_securitygroup
};

@documentation {
    list of Neutron linuxbridge service sections
};
type openstack_neutron_linuxbridge_config = {
    'linux_bridge' : openstack_neutron_linux_bridge
    'vxlan' ? openstack_neutron_vxlan
    'securitygroup' ? openstack_neutron_securitygroup
};

@documentation {
    list of Neutron openvswitch service sections
};
type openstack_neutron_openvswitch_config = {
    'ovs' : openstack_neutron_ovs
    'securitygroup' ? openstack_neutron_securitygroup
    'agent' ? openstack_neutron_agent
};

@documentation {
    list of Neutron layer3 service sections
};
type openstack_neutron_l3_config = {
    'DEFAULT' : openstack_DEFAULTS
};

@documentation {
    list of Neutron dhcp service sections
};
type openstack_neutron_dhcp_config = {
    'DEFAULT' : openstack_DEFAULTS
};

@documentation {
    list of Neutron metadata service sections
};
type openstack_neutron_metadata_config = {
    'DEFAULT' : openstack_DEFAULTS
};

@documentation {
    list of Neutron service configuration sections
}
type openstack_neutron_service_config = {
    include openstack_neutron_common
    'database' ? openstack_database
    @{nova section has the same options than "keystone_authtoken" but with the nova user and passwod}
    'nova' ? openstack_domains_common
};


@documentation {
    list of Neutron service configuration sections
}
type openstack_neutron_config = {
    'service' ? openstack_neutron_service_config
    'ml2' ? openstack_neutron_ml2_config
    'linuxbridge' ? openstack_neutron_linuxbridge_config
    'openvswitch' ? openstack_neutron_openvswitch_config
    'l3' ? openstack_neutron_l3_config
    'dhcp' ? openstack_neutron_dhcp_config
    'metadata' ? openstack_neutron_metadata_config
};

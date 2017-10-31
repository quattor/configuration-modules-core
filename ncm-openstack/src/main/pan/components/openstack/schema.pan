${componentschema}

include 'quattor/schema';
include 'pan/types';
include 'components/openstack/common';
include 'components/openstack/keystone';
include 'components/openstack/nova';
include 'components/openstack/glance';
include 'components/openstack/neutron';
include 'components/openstack/horizon';

@documentation {
Type to define OpenStack identity services
}
type openstack_identity_config = {
    'keystone' : openstack_keystone_config
};

@documentation {
Type to define OpenStack storage services
}
type openstack_storage_config = {
    'glance' ? openstack_glance_config
};

@documentation {
Type to define OpenStack compute services
}
type openstack_compute_config = {
    'nova' ? openstack_nova_config
    'nova_compute' ? openstack_nova_compute_config
};

@documentation {
Type to define OpenStack network services
}
type openstack_network_config = {
    'neutron' ? openstack_neutron_config
    'neutron_ml2' ? openstack_neutron_ml2_config
    'neutron_linuxbridge' ? openstack_neutron_linuxbridge_config
    'neutron_l3' ? openstack_neutron_l3_config
    'neutron_dhcp' ? openstack_neutron_dhcp_config
};

@documentation {
Type to define OpenStack dashboard services
}
type openstack_dashboard_config = {
    'horizon' ? openstack_horizon_config
};

@documentation {
Type to define OpenStack services
Keystone, Nova, Neutron, etc
}
type openstack_component = {
    include structure_component
    'keystone' : openstack_keystone_config
    'nova' ? openstack_nova_config
    'nova_compute' ? openstack_nova_compute_config
    'glance' ? openstack_glance_config
    'neutron' ? openstack_neutron_config
    'neutron_ml2' ? openstack_neutron_ml2_config
    'neutron_linuxbridge' ? openstack_neutron_linuxbridge_config
    'neutron_l3' ? openstack_neutron_l3_config
    'neutron_dhcp' ? openstack_neutron_dhcp_config
    'horizon' ? openstack_horizon_config
    'openrc' : openstack_openrc_config
};

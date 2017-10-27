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
Type to define OpenStack services
Keystone, Nova, Neutron, etc
}
type component_openstack = {
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
};

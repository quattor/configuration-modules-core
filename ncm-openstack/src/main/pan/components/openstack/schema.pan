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
    'neutron_compute' ? openstack_neutron_common
    'horizon' ? openstack_horizon_config
};

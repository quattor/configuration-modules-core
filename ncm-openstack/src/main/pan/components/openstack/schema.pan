${componentschema}

include 'quattor/schema';
include 'pan/types';
include 'components/openstack/common';

include 'components/openstack/identity';
include 'components/openstack/nova';
include 'components/openstack/glance';
include 'components/openstack/cinder';
include 'components/openstack/manila';
include 'components/openstack/neutron';
include 'components/openstack/horizon';

@documentation {
Type to define OpenStack storage services
}
type openstack_storage_config = {
    'glance' ? openstack_glance_config
} with openstack_oneof(SELF, 'glance');

@documentation {
Type to define OpenStack volume services
}
type openstack_volume_config = {
    'cinder' ? openstack_cinder_config
} with length(SELF) == 1;

@documentation {
Type to define OpenStack shared services
}
type openstack_share_config = {
    'manila' ? openstack_manila_config
} with length(SELF) == 1;

@documentation {
Type to define OpenStack compute services
}
type openstack_compute_config = {
    'nova' ? openstack_nova_config
} with openstack_oneof(SELF, 'nova');

@documentation {
Type to define OpenStack network services
}
type openstack_network_config = {
    'neutron' ? openstack_neutron_config
} with openstack_oneof(SELF, 'neutron');

@documentation {
Type to define OpenStack dashboard services
}
type openstack_dashboard_config = {
    'horizon' ? openstack_horizon_config
} with openstack_oneof(SELF, 'horizon');

@documentation {
Type to define OpenStack messaging services
}
type openstack_messaging_config = {
    'rabbitmq' ? openstack_rabbitmq_config
} with openstack_oneof(SELF, 'rabbitmq');

@documentation{
Hyperviosr configuration.
}
type openstack_hypervisor_config = {
};

@documentation {
Type to define OpenStack services
Keystone, Nova, Neutron, etc
}
type openstack_component = {
    include structure_component
    'identity' ? openstack_identity_config
    'compute' ? openstack_compute_config
    'storage' ? openstack_storage_config
    'share' ? openstack_share_config
    'volume' ? openstack_volume_config
    'network' ? openstack_network_config
    'dashboard' ? openstack_dashboard_config
    'messaging' ? openstack_messaging_config
    'openrc' ? openstack_openrc_config
    @{Hypervisor configuration. Host is a hypervisor when this attribute exists}
    'hypervisor' ? openstack_hypervisor_config
};

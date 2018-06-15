${componentschema}

include 'quattor/schema';
include 'pan/types';
include 'components/openstack/common';

include 'components/openstack/identity';
include 'components/openstack/compute';
include 'components/openstack/storage';
include 'components/openstack/volume';
include 'components/openstack/share';
include 'components/openstack/network';
include 'components/openstack/dashboard';

include 'components/openstack/messaging';

@documentation{
Hypervisor configuration.
}
type openstack_hypervisor_config = {
};

@documentation {
Type to define OpenStack services.
For actual OpenStack services (like identity, compute, ...), the structure
has an optional client substructure (this is service configuration data to be set via
the API client); and the other attributes are possble flavours
(e.g. like keystone flavour for identity).
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

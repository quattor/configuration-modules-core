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
include 'components/openstack/orchestration';
include 'components/openstack/messaging';

@documentation{
Hypervisor configuration.
}
type openstack_hypervisor_config = {
};

@documentation{
Type that sets the OpenStack OpenRC script configuration
}
type openstack_openrc_config = {
    include openstack_region_common
    'os_username' : string = 'admin'
    'os_password' : string
    'os_project_name' : string = 'admin'
    'os_user_domain_name' : string = 'Default'
    'os_project_domain_name' : string = 'Default'
    'os_auth_url' : type_absoluteURI
    'os_identity_api_version' : long(1..) = 3
    'os_image_api_version' : long(1..) = 2
};

@documentation{
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
    'orchestration' ? openstack_orchestration_config
    'openrc' ? openstack_openrc_config
    @{Hypervisor configuration. Host is a hypervisor when this attribute exists}
    'hypervisor' ? openstack_hypervisor_config
};

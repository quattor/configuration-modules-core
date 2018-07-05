# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/openstack/compute;

include 'components/openstack/compute/nova';

@documentation{
Type to define OpenStack compute services
}
type openstack_compute_config = {
    'nova' ? openstack_nova_config
} with openstack_oneof(SELF, 'nova');

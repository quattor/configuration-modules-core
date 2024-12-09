# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/openstack/key-manager;

include 'components/openstack/key-manager/barbican';

@documentation{
    Type to define OpenStack Key Manager service
}
type openstack_key_manager_config = {
    'barbican' ? openstack_barbican_config
} with openstack_oneof(SELF, 'barbican');

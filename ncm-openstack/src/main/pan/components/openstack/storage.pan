# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/openstack/storage;

include 'components/openstack/storage/glance';

@documentation {
Type to define OpenStack storage services
}
type openstack_storage_config = {
    'glance' ? openstack_glance_config
} with openstack_oneof(SELF, 'glance');

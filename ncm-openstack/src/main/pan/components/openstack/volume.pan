# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/openstack/volume;

include 'components/openstack/volume/cinder';

@documentation{
Type to define OpenStack volume services
}
type openstack_volume_config = {
    'cinder' ? openstack_cinder_config
} with openstack_oneof(SELF, 'cinder');

# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/openstack/image;

include 'components/openstack/image/glance';

@documentation{
Type to define OpenStack image services
}
type openstack_image_config = {
    'glance' ? openstack_glance_config
} with openstack_oneof(SELF, 'glance');

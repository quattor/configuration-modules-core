# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/openstack/rating;

include 'components/openstack/rating/cloudkitty';

@documentation{
Type to define OpenStack rating services
}
type openstack_rating_config = {
    'cloudkitty' ? openstack_cloudkitty_config
} with openstack_oneof(SELF, 'cloudkitty');

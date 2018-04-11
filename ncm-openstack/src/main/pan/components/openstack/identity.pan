# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/openstack/identity;

include 'components/openstack/identity/keystone';

@documentation {
Type to define OpenStack identity services
}
type openstack_identity_config = {
    'keystone' ? openstack_keystone_config
} with openstack_oneof(SELF, 'keystone');

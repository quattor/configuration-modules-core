# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/openstack/identity;

include 'components/openstack/identity/keystone';

type openstack_identity_region = {
    'description' : string
    'parent_region_id' ? openstack_region
};

@documentation {
Type to define OpenStack identity v3 services
}
type openstack_identity_config = {
    'keystone' ? openstack_keystone_config
    @{region, key is used as region id}
    'region' ? openstack_identity_region{}
} with openstack_oneof(SELF, 'keystone');

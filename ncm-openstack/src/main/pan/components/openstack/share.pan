# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/openstack/share;

include 'components/openstack/share/manila';

@documentation {
Type to define OpenStack shared services
}
type openstack_share_config = {
    'manila' ? openstack_manila_config
} with openstack_oneof(SELF, 'manila');


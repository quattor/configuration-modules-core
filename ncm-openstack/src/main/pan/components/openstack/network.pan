# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/openstack/network;

include 'components/openstack/network/neutron';

@documentation {
Type to define OpenStack network services
}
type openstack_network_config = {
    'neutron' ? openstack_neutron_config
} with openstack_oneof(SELF, 'neutron');


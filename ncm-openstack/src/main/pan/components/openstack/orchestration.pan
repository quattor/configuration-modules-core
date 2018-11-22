# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/openstack/orchestration;

include 'components/openstack/orchestration/heat';

@documentation {
Type to define OpenStack orchestration services
}
type openstack_orchestration_config = {
    'heat' ? openstack_heat_config
} with openstack_oneof(SELF, 'heat');

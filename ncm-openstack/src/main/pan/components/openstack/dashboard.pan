# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/openstack/dashboard;

include 'components/openstack/dashboard/horizon';

@documentation {
Type to define OpenStack dashboard services
}
type openstack_dashboard_config = {
    'horizon' ? openstack_horizon_config
} with openstack_oneof(SELF, 'horizon');


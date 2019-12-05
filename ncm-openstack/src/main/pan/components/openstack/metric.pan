# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/openstack/metric;

include 'components/openstack/metric/ceilometer';

@documentation{
Type to define OpenStack metric services
}
type openstack_metric_config = {
    'ceilometer' ? openstack_ceilometer_config
} with openstack_oneof(SELF, 'ceilometer');

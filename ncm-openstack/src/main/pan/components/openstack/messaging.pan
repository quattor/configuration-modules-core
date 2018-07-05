# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/openstack/messaging;

include 'components/openstack/messaging/rabbitmq';

@documentation{
Type to define OpenStack messaging services
}
type openstack_messaging_config = {
    'rabbitmq' ? openstack_rabbitmq_config
} with openstack_oneof(SELF, 'rabbitmq');


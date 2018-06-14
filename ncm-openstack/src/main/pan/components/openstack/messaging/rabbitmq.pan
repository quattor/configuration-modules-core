# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/openstack/messaging/rabbitmq;

@documentation {
    Type to enable RabbitMQ and the message system for OpenStack.
}
type openstack_rabbitmq_config = {
    @{RabbitMQ user to get access to the queue}
    'user' : string = 'openstack'
    'password' : string
    @{Set config/write/read permissions for RabbitMQ service.
    A regular expression matching resource names for
    which the user is granted configure permissions}
    'permissions' : string[3] = list('.*', '.*', '.*')
};

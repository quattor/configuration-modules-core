${componentschema}

include 'quattor/types/component';

type network_component = {
    include structure_component
    @{experimental: rename (physical) devices}
    'rename' ? boolean

    @{
        A dict mapping daemon name to CAF::Service action to take if the network configuration changes.
        e.g. 'daemons/firewalld' = 'reload';
    }
    'daemons' ? caf_service_action{}
};

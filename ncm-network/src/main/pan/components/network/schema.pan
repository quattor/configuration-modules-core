${componentschema}

include 'quattor/types/component';

type network_component = {
    include structure_component
    @{experimental: rename (physical) devices}
    'rename' ? boolean
};

${componentschema}

include 'quattor/types/component';
include 'pan/types';

type pcs_score = string with match(SELF, '^(-?\d+|-?INFINITY)$');

type pcs_cluster = {
    @{name of the cluster}
    'name' : string
    @{nodes in the cluster}
    'nodes' : type_hostname[]
    @{internal network node names (same order as nodes)}
    'internal' ? type_hostname[]
};

@{common device type for e.g. resource and stonith}
type pcs_common_device = {
    @{device options}
    'option' ? string{}
    @{meta options}
    'meta' ? string{}
    @{add to group}
    'group' ? string
    @{before other device}
    'before' ? string
    @{after other device}
    'after' ? string
    @{disabled}
    'disabled' ? boolean
    @{wait (when specified) for start in seconds}
    'wait' ? long(0..) = 60
};

@{stonith device type}
type pcs_stonith = {
    include pcs_common_device
    @{stonith device type (e.g. fence_ipmilan)}
    'type' : string
    @{operations (key is operation action; value are the options)}
    'operation' ? string{}{}
};

@{resource operation type}
type pcs_resource_operation = {
    @{unique name (generated if not defined)}
    'id' ? string
    @{action name}
    'name' ? string with match(SELF, '^(start|stop|monitor|promote|demote|notify)$')
    @{How frequently (in seconds) to perform the operation}
    'interval' ? long(0..)
    @{How long to wait before declaring the action has failed }
    'timeout' ? long(0..)
    @{The action to take if this action ever fails}
    'on-fail' ? string with match(SELF, '^(ignore|block|stop|restart|fence|standby)$')
    @{If false, ignore this operation definition.}
    'enabled' ? boolean
    @{If true, the intention to perform the operation is recorded}
    'record-pending' ? boolean
    @{Run the operation only on node(s) that the cluster thinks should be in the specified role.}
    'role' ? string with match(SELF, '^(Stopped|Started|Slave|Master)$')
};

@{resource type. special cases:
    type = master: without standard or provider, create a named master
        from existing resource (or group)
        (specified by single element master dict() resource=resource_id)
}
type pcs_resource = {
    include pcs_common_device
    @{resource device standard ([standard[:provider]:]type) (e.g. ocf)}
    'standard' ? string
    @{resource device provider ([standard[:provider]:]type) (e.g. heartbeat)}
    'provider' ? string
    @{resource device type ([standard[:provider]:]type) (e.g. IPaddr2)
      or special cases like master}
    'type' : string
    @{create clone with options}
    'clone' ? string{}
    @{create master/slave with options}
    'master' ? string{}
    @{create inside bundle}
    'bundle' ? string
    @{operations (key is operation action (unless name attribute is set); value are the options)}
    'operation' ? pcs_resource_operation{}
} with {
    if (SELF['type'] == 'master' &&
        !exists(SELF['standard']) &&
        !exists(SELF['provider'])) {
        if (! exists(SELF['master']) ||
            length(SELF['master']) != 1 ||
            ! exists(SELF['master']['resource'])) {
            error('named master requires single element master attribute with resource name');
        };
    };
    true;
};

type pcs_contraint_colocation_resource = {
    'name' : string
    @{when defined, true sets master and false sets slave}
    'master' ? boolean
};

type pcs_constraint_colocation = {
    'source' : pcs_contraint_colocation_resource
    'target' : pcs_contraint_colocation_resource
    'score' ? pcs_score
    'options' ? string{}
};

type pcs_contraint_order_resource = {
    'name' : string
    'action' ? string with match(SELF, '^(start|stop|promote|demote)$')
};

type pcs_constraint_order = {
    'source' : pcs_contraint_order_resource
    'target' : pcs_contraint_order_resource
    'options' ? string{}
};

type pcs_constraint_location = {
    @{key is resource, value dict of node(s) with their score(s)}
    'avoids' ? pcs_score{}{}
};

type pcs_constraint = {
    'colocation' ? pcs_constraint_colocation[]
    'location' ? pcs_constraint_location
    'order' ? pcs_constraint_order[]
};

type pcs_default_resource = {
    'migration-threshold' ? long(0..)
    'resource-stickiness' ? long(0..)
};

type pcs_default_resource_op = {
    @{timeout (in seconds)}
    'timeout' ? long(0..)
};

# keys: split on _ for subcommands
type pcs_default = {
    @{resource default option(s)}
    'resource' ? pcs_default_resource
    @{resource op default option(s)}
    'resource_op' ? pcs_default_resource_op
};

type pcs_component = {
    include structure_component
    'cluster' : pcs_cluster
    @{stonith device(s); key is device name}
    'stonith' : pcs_stonith{}
    @{resource(s); key is device name}
    'resource' : pcs_resource{}
    @{constraint(s)}
    'constraint' ? pcs_constraint
    @{defaults}
    'default' ? pcs_default
};

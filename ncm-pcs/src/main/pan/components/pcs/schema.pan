${componentschema}

include 'quattor/types/component';
include 'pan/types';

type pcs_cluster = {
    'name' : string
    'nodes' : type_hostname[]
};

type pcs_component = {
    include structure_component
    'cluster' : pcs_cluster
};

# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/opennebula/schema;

include {'quattor/schema'};
include {'pan/types'};

type component_opennebula = {
    include structure_component
};

bind '/software/components/opennebula' = component_opennebula;

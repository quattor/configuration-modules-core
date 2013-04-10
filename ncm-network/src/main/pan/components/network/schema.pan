# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/network/schema;

include { 'quattor/schema' };


type component_network_type = {
	include structure_component
};


bind "/software/components/network" = component_network_type;

# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/oramonserver/schema;

include {'quattor/schema'};
# Old Quattor 1.1 use this instead 
#include components/type;

type component_oramonserver_type = {
    include structure_component
    # Old Quattor 1.1 use this instead 
    #include component_type
    "conf" : structure_monitoring
};

bind "/software/components/oramonserver" = component_oramonserver_type;


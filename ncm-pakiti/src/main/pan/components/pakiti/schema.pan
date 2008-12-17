# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/pakiti/schema;

include quattor/schema;


type component_pakiti_type = {
    include structure_component
    "admin" : string
    "server_url" : string
    "method" : string
};

type "/software/components/pakiti" = component_pakiti_type;


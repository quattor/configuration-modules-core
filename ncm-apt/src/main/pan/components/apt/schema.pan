# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/apt/schema;

include {'quattor/schema'};

type structure_apt = {
    "something" : string
};

type component_apt = {
    include structure_component
    "config" ? structure_apt[]
};

bind "/software/components/apt" = component_apt;



# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/interactivelimits/schema;

include 'quattor/schema';

type component_interactivelimits_type = {
    include structure_component
    # arrays of array like this [<domain> <type> <item> <value>]
    "values" : list
};

bind "/software/components/interactivelimits" = component_interactivelimits_type;

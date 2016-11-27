# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/interactivelimits/schema;

include 'quattor/types/component';

type component_interactivelimits_type = {
    include structure_component
    # arrays of array like this [<domain> <type> <item> <value>]
    "values" : string[][]
};

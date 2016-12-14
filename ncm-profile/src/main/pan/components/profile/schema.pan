# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/profile/schema;

include 'quattor/schema';

function component_profile_script_valid = {
    if ( exists(SELF['flavors']) && is_defined(SELF['flavors']) ) {
        if ( is_list(SELF['flavors']) ) {
            foreach (i;flavor;SELF['flavors']) {
                if ( !match(flavor, 'csh|sh') ) {
                    error("Invalid script flavor '"+flavor+"'. Must be 'csh' or 'sh'");
                    return(false);
                };
            };
        } else {
            error("Script 'flavors' must a list");
            return(false);
        };
    };

    # When no suffix is appended to base name, restrict to one flavor
    if ( !SELF['flavorSuffix'] && (length(SELF['flavors']) > 1) ) {
        error("Only one flavor is allowed when flavorSuffix is false");
    };

    return(true);
};

type structure_profile_path = {
    'prepend' ? string[]
    'append' ? string[]
    'value' ? string[]
};

type structure_profile_script = {
    'flavors' : string[]=list('sh', 'csh')
    'env' ? string{}
    'path' ? structure_profile_path{}
    'flavorSuffix' : boolean = true
} with component_profile_script_valid(SELF);

type component_profile = {
    include structure_component
    include structure_profile_script
    'configDir' ? string
    'configName' ? string
    'scripts' ? structure_profile_script{}
};

bind '/software/components/profile' = component_profile;

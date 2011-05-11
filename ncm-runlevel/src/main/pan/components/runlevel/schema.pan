# ${license-info}
# ${developer-info}
# ${author-info}

# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

declaration template components/runlevel/schema;

include {'quattor/schema'};

function is_valid_runlevel = {
    level = ARGV[0];
    if(level>0 && level<6) return(true);
    error("Invalid runlevel value: " + to_string(level));
    return(false);
};

type component_runlevel_type = {
    include structure_component
    "initdefault" : long with { is_valid_runlevel(SELF)}
};

bind "/software/components/runlevel" = component_runlevel_type;


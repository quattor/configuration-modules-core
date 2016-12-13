# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/named
#
############################################################

declaration template components/named/schema;

include 'quattor/schema';

function component_named_valid = {
    function_name = 'component_named_valid';
    if ( ARGC != 1 ) {
        error(function_name+': this function requires 1 argument');
    };

    if ( exists(SELF['serverConfig']) && exists(SELF['configfile']) ) {
        error(function_name+": properties 'serverConfig' and 'configfile' are mutually exclusive.");
    };

    true;
};

type component_named = {
    include structure_component
    "serverConfig" ? string
    "configfile" ? string
    "use_localhost" : boolean = true
    "start" ? boolean
    "servers" ? type_ip[..3]
    "options" ? string[]
    "search" ? type_fqdn[..6] with { length(replace('(^\[ )|,|( \])$', '', to_string(SELF))) <= 256 }
} with component_named_valid(SELF);

bind "/software/components/named" = component_named;

# ${license-info}
# ${developer-info}
# ${author-info}

###############################################################################
# Coding style: emulate <TAB> characters with 4 spaces, thanks!
###############################################################################

declaration template components/resolver/schema;

include 'quattor/schema';

type component_resolver_type = {
    include structure_component
    'servers' : type_ip[..3]
    'search' ? type_fqdn[..6] with { length(replace('(^\[ )|,|( \])$', '', to_string(SELF))) <= 256 }
    'dnscache' : boolean = false
};

bind "/software/components/resolver" = component_resolver_type;

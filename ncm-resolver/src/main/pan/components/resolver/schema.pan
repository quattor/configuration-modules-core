# ${license-info}
# ${developer-info}
# ${author-info}

###############################################################################
# Coding style: emulate <TAB> characters with 4 spaces, thanks!
###############################################################################

declaration template components/resolver/schema;

include 'quattor/schema';

@{See resolv.conf(5). The code supports both boolean options, and those
  which take an argument (e.g. timeout:n).  The component does not
  introspect these keys, just the type, so new keys can be added to this
  resource and the component will write them.
}
type type_resolver_options = {
    'rotate' ? boolean
    'timeout' ? long(0..30)
};

type component_resolver_type = {
    include structure_component
    'servers' : type_ip[..3]
    'search' ? type_fqdn[..6] with { length(replace('(^\[ )|,|( \])$', '', to_string(SELF))) <= 256 }
    'dnscache' : boolean = false
    'options' ? type_resolver_options
};

bind "/software/components/resolver" = component_resolver_type;

# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/named
#
#
#
#
############################################################

declaration template components/named/schema;

include { 'quattor/schema' };

type component_named = {
    include structure_component
    "configfile"    ? string
    "start"         : boolean = false
    "servers"       ? string[]
    "options"       ? string[]
    "search"        ? type_fqdn[]
};

bind "/software/components/named" = component_named;

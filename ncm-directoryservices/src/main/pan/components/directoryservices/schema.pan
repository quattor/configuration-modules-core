# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/directoryservices
#
#
#
#
############################################################

declaration template components/directoryservices/schema;

include 'quattor/schema';

type directoryservices_ldap_entry = extensible {
};

type component_directoryservices = {
    include structure_component
        "search" : list
        "ldapv3" ? directoryservices_ldap_entry{}
};

bind "/software/components/directoryservices" = component_directoryservices;


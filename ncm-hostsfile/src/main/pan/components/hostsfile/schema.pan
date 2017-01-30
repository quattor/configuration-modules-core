# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/hostsfile
#
#
#
############################################################

declaration template components/hostsfile/schema;

include 'quattor/schema';

type component_hostsfile_type = {
    include structure_component
    "file" ? string        # File to store in.  Default is /etc/hosts
    "entries" : dict
    "takeover" : boolean = false
};

bind "/software/components/hostsfile" = component_hostsfile_type;

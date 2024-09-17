# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/sysctl
#
############################################################

declaration template components/sysctl/schema;

include 'quattor/schema';

type component_sysctl_structure = {
    include structure_component

    'command' : string = '/sbin/sysctl' with match(SELF, '^/.+')
    'compat-v1' ? boolean with deprecated(0, 'compat-v1 has no effect and will be removed in a future release')
    'confFile' : string = '/etc/sysctl.conf' with match(SELF, '^(/.+|[^/]+)\.conf$') # disallow / unless an absolute path is supplied.
    'variables' ? string{}
};

bind "/software/components/sysctl" = component_sysctl_structure;

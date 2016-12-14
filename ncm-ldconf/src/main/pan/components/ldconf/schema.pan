# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/ldconf/schema;

include 'quattor/schema';

type component_ldconf = {
    include structure_component
    'conffile' : string = '/etc/ld.so.conf'
    'paths' ? string[]
};

bind '/software/components/ldconf' = component_ldconf;



# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/opennebula/schema;

include 'quattor/schema';
include 'pan/types';

include 'metaconfig/opennebula/schema';

type opennebula_rpc = {
    "port" : long(0..) = 2633
    "host" : string = 'localhost'
    "user" : string = 'oneadmin'
    "password" : string
} = nlist();

type component_opennebula = {
    include structure_component
    "rpc" : opennebula_rpc
} = nlist();

bind '/software/components/opennebula' = component_opennebula;

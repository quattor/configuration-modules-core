declaration template metaconfig/opennebula/schema;

include 'pan/types';

type aii_section = {
    "name" : string
    "password" : string
    "host" : string
    "port" ? long
    "user" ? string
};

@documentation{
aii/opennebula.conf sections
}
type aii_opennebula_conf = {
    "sections" : aii_section[]
};
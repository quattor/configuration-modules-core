declaration template metaconfig/opennebula/schema;

include 'pan/types';

type aii_section = {
    "password" : string
    "host" : string
    "port" ? long
    "user" ? string
    "pattern" ? string
} = dict();

@documentation{
aii/opennebula.conf sections
}
type aii_opennebula_conf = aii_section{};

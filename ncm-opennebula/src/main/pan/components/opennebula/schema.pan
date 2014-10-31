# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/opennebula/schema;

include 'quattor/schema';
include 'pan/types';

@{
TODO: resolve dependency on metaconfig template repository
@}
include 'metaconfig/opennebula/schema';

@{ 
Type that sets the OpenNebula conf
to contact to ONE RPC server
@}
type opennebula_rpc = {
    "port" : long(0..) = 2633
    "host" : string = 'localhost'
    "user" : string = 'oneadmin'
    "password" : string
} = nlist();

@{
Type to define ONE basic resources
datastores, vnets, hosts names, etc
@}
type component_opennebula = {
    include structure_component
    'datastores'    : opennebula_datastore[1..]
    'users'         : opennebula_user[]
    'vnets'         : opennebula_vnet[]
    'hosts'         : string[]
    'rpc'           : opennebula_rpc
    'ssh_multiplex' : boolean = true
    'tm_system_ds'  ? string with match(SELF, "^(shared|ssh|vmfs)$")
} = nlist();

bind '/software/components/opennebula' = component_opennebula;

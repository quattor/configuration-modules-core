declaration template metaconfig/example/schema;

include 'pan/types';

type example_service = {
    'hosts' :  type_hostname[]
    'port' : long(0..)
    'master' : boolean
    'description' : string
    'option' ? string
};

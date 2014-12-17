declaration template metaconfig/pakiti/schema;

include 'pan/types';

type pakiti_client2 = {
    'server_name' : type_hostname
    'port' : type_port = 80
    'url' : string = '/feed/'
    'ca_path' ? string
    'tag' ? string
    'connection_method' ? string
};

declaration template metaconfig/pakiti/server_schema3;

include 'pan/types';

type pakiti_server3 = {
    'dbhost' : type_hostname
    'dbname' : string = 'pakiti'
    'dbpassword' : string
    'dbuser': string = 'pakiti'
    'name' : string
};

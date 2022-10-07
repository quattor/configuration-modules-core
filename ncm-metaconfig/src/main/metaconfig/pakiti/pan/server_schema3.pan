declaration template metaconfig/pakiti/server_schema3;

include 'pan/types';

type pakiti_server3 = {
    'dbhost' : type_hostname
    'dbname' : string_trimmed = 'pakiti'
    'dbpassword' : string_trimmed
    'dbuser': string_trimmed = 'pakiti'
    'name' : string_trimmed
};

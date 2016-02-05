declaration template metaconfig/icinga-web/schema;

include 'pan/types';

type iw_caching_opts = {
    'enabled' : boolean
    'driver' : string = 'apc' with match (SELF, "^(apc|memcache)$")
    'use_query_cache' : boolean
    'use_result_cache' ? boolean
    'result_cache_lifespan' ? long(0..) = 60
};

type icinga_database_dsn = {
    'protocol' : string with match (SELF, "^(pgsql|mysql|oracle)$")
    'hostname' : type_hostname
    'username' : string
    'password' : string
    'port' : type_port
    'database_name' : string
};

type manager_attribute = {
    'attr_model_loading' : string = 'CONSERVATIVE' with match (SELF, "^(CONSERVATIVE|AGGRESSIVE)$")
};

type icinga_database = {
    'dsn' : icinga_database_dsn
    'charset' : string ='utf8' with match (SELF, "^(utf8)$")
    'manager_attributes' : manager_attribute
    'caching' : iw_caching_opts
    'prefix' ? string
    'use_retained' ? boolean
    'load_models' : string
    'models_directory' : string
    'class' : string with match (SELF, "^(AppKitDoctrineDatabase|IcingaDoctrineDatabase)$")
};

type icinga_web_service = {
    'icinga_db' : icinga_database
    'icinga_web_db' : icinga_database
};

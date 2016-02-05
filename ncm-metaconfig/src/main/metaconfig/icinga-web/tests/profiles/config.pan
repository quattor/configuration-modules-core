object template config;

include 'metaconfig/icinga-web/config';

prefix '/software/components/metaconfig/services/{/usr/share/icinga-web/app/config/databases.xml}/contents';

'icinga_db' = dict(
    'dsn', dict(
        'protocol', 'mysql',
        'hostname', 'localhost',
        'username', 'icinga',
        'password', 'icinga',
        'port', 3306,
        'database_name', 'icinga',
        ),
    'charset', 'utf8',
    'manager_attributes', dict(
        'attr_model_loading', 'CONSERVATIVE',
        ),
    'caching',  dict(
        'enabled', false,
        'driver', 'apc',
        'use_query_cache', true,
        ),
    'prefix', 'icinga_',
    'use_retained', true,
    'load_models', '%core.module_dir%/Api/lib/database/models/generated',
    'models_directory', '%core.module_dir%/Api/lib/database/models',
    'class', 'IcingaDoctrineDatabase',
);

'icinga_web_db' = dict(
    'dsn', dict(
        'protocol', 'mysql',
        'hostname', 'localhost',
        'username', 'icinga_web',
        'password', 'icinga_web',
        'port', 3306,
        'database_name', 'icinga_web',
        ),
    'charset', 'utf8',
    'manager_attributes', dict(
        'attr_model_loading', 'CONSERVATIVE',
        ),
    'caching',  dict(
        'enabled', false,
        'driver', 'apc',
        'use_query_cache', true,
        'use_result_cache', true,
        'result_cache_lifespan', 60,
        ),
    'load_models', '%core.module_dir%/AppKit/lib/database/models/generated',
    'models_directory', '%core.module_dir%/AppKit/lib/database/models',
    'class', 'AppKitDoctrineDatabase',
);

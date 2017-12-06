# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/mysql/schema;

include 'quattor/schema';


function component_mysql_valid = {
    function_name = 'component_mysql_valid';
    if ( ARGC != 1 ) {
        error(function_name + ': this function requires 1 argument');
    };


    conf = SELF;
    if ( exists(conf['databases']) && is_defined(conf['databases']) ) {
        foreach (db; params; conf['databases']) {
            if ( !exists(conf['servers'][params['server']]) || !is_defined(conf['servers'][params['server']]) ) {
                error('Database ' + db + ' uses server ' + params['server'] + ' but this server is not defined');
            };
        };
    };


    return(true);
};


function component_mysql_check_db_script = {
    if ((exists(SELF['file']) && is_defined(SELF['file'])) ||
        (exists(SELF['content']) && is_defined(SELF['content']))) {
            return(true);
    } else {
        error('Invalid DB script : either script name or script content must be specified');
    };
};


# The function validating password imposes a non-empty string.
function component_mysql_password_valid = {
    if (match(SELF, '^[^\\]+$')) {
        true;
    } else {
        false;
    };
};


type component_mysql_user_right = string with match(SELF, '^(ALL( PRIVILEGES)?|ALTER( ROUTINE)?|' +
    'CREATE( (ROUTINE|TEMPORARY TABLES|USER|VIEW))?|DELETE|DROP|EVENT|EXECUTE|FILE|GRANT OPTION|INDEX|INSERT|' +
    'LOCK TABLES|PROCESS|REFERENCES|RELOAD|REPLICATION (CLIENT|SLAVE)|SELECT|SHOW (DATABASES|VIEW)|SHUTDOWN|' +
    'SUPER|TRIGGER|UPDATE|USAGE)$');


type component_mysql_db_user = {
    'password' : string with (length(SELF) == 0) || component_mysql_password_valid(SELF)
    'rights' : component_mysql_user_right[] = list('SELECT')
    'shortPwd' : boolean = false
};


type component_mysql_db_script = {
    'file' ? string
    'content' ? string
} with component_mysql_check_db_script(SELF);


type component_mysql_db_options = {
    'server' : string
    'users' ? component_mysql_db_user{}
    'initScript' ? component_mysql_db_script
    'initOnce' : boolean = true
    'createDb' : boolean = true
    # tableOptions is a dict of table where value is a dict of parameter/value pairs.
    # If the parameter contains spaces, it must be escaped.
    'tableOptions' ? string{}{}
};


type component_mysql_server_options = {
    'host' ? string
    'adminuser' : string
    'adminpwd' : string with component_mysql_password_valid(SELF)
    'options' ? string{}
    'users' ? component_mysql_db_user{}
};


type component_mysql = {
    include structure_component

    'databases' ? component_mysql_db_options{}
    'servers' : component_mysql_server_options{}
    'serviceName' : string = 'mysqld' with match(SELF, '^(mysql|mysqld|mariadb)$')
} with component_mysql_valid(SELF);


bind '/software/components/mysql' = component_mysql;

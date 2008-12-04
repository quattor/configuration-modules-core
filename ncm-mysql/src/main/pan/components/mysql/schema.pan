# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/mysql/schema;

include { 'quattor/schema' };

function component_mysql_valid = {
  function_name = 'component_mysql_valid';
  if ( ARGC != 1 ) {
    error(function_name+': this function requires 1 argument');
  };
  
  conf = SELF;
  if ( exists(conf['databases']) && is_defined(conf['databases']) ) {
    foreach (db;params;conf['databases']) {
      if ( !exists(conf['servers'][params['server']]) || !is_defined(conf['servers'][params['server']]) ) {
        error('Database '+db+' uses server '+params['server']+' but this server is not defined');
      };
    };
  };
  
  return(true);
};

function component_mysql_check_db_script = {
 if ( (exists(SELF['file']) && is_defined(SELF['file'])) ||
      (exists(SELF['content']) && is_defined(SELF['content'])) ) {
    return(true);
  } else {
    error('Invalid DB script : either script name or script content must be specified');
  };
};

type component_mysql_db_user = {
  'password'  : string
  'rights'    : string[]
  'shortPwd'  : boolean = false
};

type component_mysql_db_script = {
  'file'      ? string
  'content'   ? string
} with component_mysql_check_db_script(SELF);

type component_mysql_db_options = {
  'server'       : string
  'users'        ? component_mysql_db_user{}
  'initScript'   ? component_mysql_db_script
  'initOnce'     : boolean = false
  # tableOptions is a nlist of table where value is a nlist of parameter/value pairs
  'tableOptions' ? string{}{}
};

type component_mysql_server_options = {
  'host'      ? string
  'adminuser' : string
  'adminpwd'  : string with length(SELF) > 0
  'options'   ? string{}
  'users'     ? component_mysql_db_user{}
};

type component_mysql = {
  include structure_component

  'databases'    ? component_mysql_db_options{}
  'servers'      : component_mysql_server_options{}
} with component_mysql_valid(SELF);

bind '/software/components/mysql' = component_mysql;



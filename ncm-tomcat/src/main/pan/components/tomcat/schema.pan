# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/tomcat/schema;

include { 'pan/structures' };



type boolstr = string with match (SELF, '(false|true)');
type dbgval = long(0..10);


type structure_tomcat_valstr = {
    "value" :   string
};

type structure_tomcat_vallng = {
    "value" :   long
};

type structure_tomcat_valboolstr = {
    "value" :  boolstr
};

####################################################################################
# nested components
###################################################################################3

# Logger
type structure_tomcat_logger_attrs = {

    "className" :   string with match(SELF, '^org.apache.catalina.logger')
    "timestamp" ?   boolstr
    "prefix"    ?   string
    "suffix"    ?   string
    "directory" ?   string
    
};


type structure_tomcat_logger = {
    "attrs" ?     structure_tomcat_logger_attrs
};
    

# Realm
type structure_tomcat_realm_attrs = {

    "className" :   string with match( SELF, '^org.apache.catalina.realm')
    "connectionName"    ?   string
    "connectionPassword"    ?   string
    "connectionURL" ?   string
    "digest"    ?   string
    "digestEncoding"    ?   string
    "driverName"    ?   string
    "roleNameCol"   ?   string
    "userCredCol"   ?   string
    "userNameCol"   ?   string
    "userRoleTable" ?   string
    "userTable" ?   string
    "debug" ?   dbgval
    "resourceName"  ?   string
    
};


type structure_tomcat_realm = {
    "attrs" :   structure_tomcat_realm_attrs
};    

# Listener
type structure_tomcat_server_listener_attrs   = {

    "className" ?   string
    "debug" ?   dbgval
};


type structure_tomcat_server_listener = {
    "attrs" ?   structure_tomcat_server_listener_attrs
};


# Resource
type structure_tomcat_res_attrs = {

    "name"  :   string
    "type"  ?   string
    "description" ? string
    "scope" ?   string with match (SELF, '(Shareable|Unshareable)')
    "auth"  ?   string  # GET BACK LATER
    
};


type structure_tomcat_res = {
    "attrs" ?   structure_tomcat_res_attrs
};


# ResourceParams -> parameter
type structure_tomcat_resparam_param_nested = {
    
    "name"  :   string
    "value" ?   string
#     "minEvictableIdleTimeMillis"    ?   structure_tomcat_vallng
#     "poolPreparedStatements"    ?   structure_tomcat_valboolstr
#     "defaultReadOnly"    ?   structure_tomcat_valboolstr
#     "maxActive" ?   structure_tomcat_vallng
#     "maxWait"   ?   structure_tomcat_vallng
#     "maxIdle"   ?   structure_tomcat_vallng
#     "minIdle"   ?   structure_tomcat_vallng
#     "password"  ?   structure_tomcat_valstr
#     "username"  ?   structure_tomcat_valstr
#     "url"   ?   structure_tomcat_valstr
#     "driverClassName"   ?   structure_tomcat_valstr
#     "factory"   ?   structure_tomcat_valstr
#     "defaultAutoCommit" ?   structure_tomcat_valboolstr
#     "numTestsPerEvictionRun"    ?   structure_tomcat_vallng
#     "initialSize"   ?   structure_tomcat_vallng
#     "timeBetweenEvictionRunsMillis" ?   structure_tomcat_vallng
#     "pathname"  ?   structure_tomcat_valstr
        
};    


type structure_tomcat_resparam_param = {
    "nested" ?  structure_tomcat_resparam_param_nested
};    

    
# ResourceParams
type structure_tomcat_resparam_attrs = {

    "name"  :   string
    
};

type structure_tomcat_resparam_nested = {

    "parameter" ?   structure_tomcat_resparam_param[]
    
};

type structure_tomcat_resparam = {
    "attrs" ?   structure_tomcat_resparam_attrs
    "nested" ?  structure_tomcat_resparam_nested
};    

#  Environment
type structure_tomcat_env_attrs = {

    "name"  :   string
    "type"  ?   string 
    "value" ?   string
    "description" ? string
    "override"  ?   string
    
};


type structure_tomcat_env = {
    "attrs" ?   structure_tomcat_env_attrs
};    


# Velvet
type structure_tomcat_valve_attrs = {

    # Access log Velvet
    "className" :   string
    "directory" ?   string
    "pattern"   ?   string
    "prefix"    ?   string
    "resolveHosts"  ?   string
    "suffix"    ?   string
    "rotatable" ?   string
    "condition" ?   string
    "fileDateFormat"    ?   string

    # Remote Address Filter
    "allow" ?   string
    "deny"  ?   string

    # Single Sign On Valve
    "requireReauthentication"   ?   boolstr
    "debug" ?   dbgval

};


type structure_tomcat_valve = {
    "attrs" :   structure_tomcat_valve_attrs
};        
    

####################################################################################
# containers
###################################################################################3


# Host
type structure_tomcat_host_attrs = {
    
    "name"  :   string
    "appBase"   ?   string
    "autoDeploy"    ?   boolstr
    "deployOnStartup"   ?   boolstr
    "backgroundProcessorDelay"  ?   long
    "className" ?   string
    "deployXML" ?   boolstr
    "errorReportValveClass" ?   string
    "unpackWARs"    ?   boolstr
    "workDir"   ?   string
    "xmlNamespaceAware" ?   boolstr
    "xmlValidation" ?   boolstr
        
    "debug" ?   dbgval
    
};
    
type structure_tomcat_host_nested = {
    
    "Logger"    ?   structure_tomcat_logger
    "Valve" ?   structure_tomcat_valve

};


type structure_tomcat_host = {

    "attrs" ?   structure_tomcat_host_attrs
    "nested" ?   structure_tomcat_host_nested

};
    
#  Connector
type structure_tomcat_conn_attrs = {

    "acceptCount"?  long
    "maxSpareThreads"   ?   long
    "minSpareThreads"   ?   long
    "maxThreads"    ?   long
    "disableUploadTimeout"  ?   boolstr
    "connectionTimeout" ?   long
    "port"  ?   long
    "redirectPort"  ?   long
    "enableLookups" ?   boolstr
    "debug" ?   dbgval
    "protocol"  ?   string
};    

type structure_tomcat_conn = {
    "attrs" ?   structure_tomcat_conn_attrs
};    

#  Engine
type structure_tomcat_eng_attrs = {
    
    "name"  :   string
    "defaultHost"   ?   string
    "debug" ?   dbgval
};
    
type structure_tomcat_eng_nested = {
    
    "Realm" ?   structure_tomcat_realm
    "Host"  ?   structure_tomcat_host
    "Logger"    ?   structure_tomcat_logger
    "Valve" ?   structure_tomcat_valve

};    


type structure_tomcat_eng = {
    "attrs" ?   structure_tomcat_eng_attrs
    "nested" ?   structure_tomcat_eng_nested
};    

####################################################################################
# server -> Service
###################################################################################3



# Service
type structure_tomcat_server_service_attrs = {

    "name"  :   string
    "debug" ?   dbgval

};    
    
type structure_tomcat_server_service_nested = {
    
    "Connector"   :   structure_tomcat_conn[]
    "Engine"  :   structure_tomcat_eng

};


type structure_tomcat_server_service = {
    "attrs" ?     structure_tomcat_server_service_attrs
    "nested" ?      structure_tomcat_server_service_nested
};    

####################################################################################
# global resrources
###################################################################################3


# GlobalNamingResources
type structure_tomcat_server_globnamres_nested = {

    "Environment"   :   structure_tomcat_env
    "Resource"  :   structure_tomcat_res
    "ResourceParams"  :   structure_tomcat_resparam

};

type structure_tomcat_server_globnamres = {
    "nested" : structure_tomcat_server_globnamres_nested
};    


####################################################################################
# server config
###################################################################################3


type structure_tomcat_server_attrs = {

    "className" ?   string
    "shutdown"  :   string
    "debug" ?   dbgval
    "port"  :   long
    
};    

type structure_tomcat_server_nested = {

    "GlobalNamingResources" ? structure_tomcat_server_globnamres
    "Service" ? structure_tomcat_server_service
    "Listener"  ?  structure_tomcat_server_listener[]

};
    
type structure_tomcat_server = {
    "attrs" ? structure_tomcat_server_attrs
    "nested" ? structure_tomcat_server_nested
};



####################################################################################
# tomcat webapps
###################################################################################3

# Context

type structure_tomcat_context_attrs = {

    "backgroundProcessorDelay"  ?   long(0..)
    "className" ?   string
    "cookies"   ?   boolstr
    "crossContext"  ?   boolstr
    "docBase"   ?   string
    "override"   ?  boolstr
    "privileged"    ?   boolstr
    "path"  ?   string
    "reloadable"    ?   boolstr
    "wrapperClass"  ?   string
    "debug" ?   dbgval

};
    
type structure_tomcat_context_nested = {
    
    include structure_tomcat_server_globnamres_nested

    "Logger"    ?   structure_tomcat_logger
    "Valve" ?   structure_tomcat_valve

};

type structure_tomcat_context = {
    "attrs" ?   structure_tomcat_context_attrs
    "nested" ?   structure_tomcat_context_nested

};    
    
type structure_tomcat_webapps = {

    "Context"   ?  structure_tomcat_context

};


####################################################################################
# tomcat manager users
###################################################################################3


type structure_tomcat_user_attrs = {

    "name": string
    "roles": string
    "password"  :   string    
    
};

type structure_tomcat_user = {
    "attrs" ?   structure_tomcat_user_attrs
};    
    

type structure_tomcat_nested = {
    
    "user"  :   structure_tomcat_user[]

};   

type structure_tomcat_users = {
    "nested" ?     structure_tomcat_nested 
};

# ####################################################################################
# # tomcat configuration
# ###################################################################################3
type structure_tomcat_config = {
 
    "JAVA_HOME" :   string
    "JAVA_OPTS" ?   string
    "CATALINA_HOME" ?   string
    "CATALINA_BASE" ?   string
    "CATALINA_TMPDIR"   ?   string
    "JASPER_HOME"   ?   string
    "JAVA_ENDORSED_DIRS"    ?   string
    "TOMCAT_USER"   ?   string
    "LANG"  ?   string
    "SHUTDOWN_WAIT" ?   long
    "CATALINA_PID"  ?   string

};



####################################################################################
# binding the component
###################################################################################3


type component_tomcat_conf = {
   "mainconf"    ?   structure_tomcat_config
   "Server" :   structure_tomcat_server
   "tomcat-users" ?   structure_tomcat_users
   "webapps"    ?   structure_tomcat_webapps{}
};


type component_tomcat = {
   include component_type

   "conf"  :   component_tomcat_conf
};       

bind "/software/components/tomcat" = component_tomcat;




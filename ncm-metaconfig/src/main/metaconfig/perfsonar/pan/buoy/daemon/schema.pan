declaration template metaconfig/perfsonar/buoy/daemon/schema;

include 'pan/types';

type perfsonarbuoy = {
    "maintenance_interval" : long(0..) = 10
    # Enable registration to the LS
    "enable_registration" : boolean = true
    # Register every hour
    "ls_registration_interval" : long(0..) = 60
    "ls_instance" : type_absoluteURI = "http://localhost:9995/perfsonar_PS/services/hLS"
    "metadata_db_file" : string = "/var/lib/perfsonar/perfsonarbuoy_ma/store.xml"
    "metadata_db_type" : string = "file"
    "owmesh" : string =  "/opt/perfsonar_ps/perfsonarbuoy_ma/etc"
    "service_accesspoint" : type_absoluteURI = "http://localhost:8085/perfsonar_PS/services/pSB"
    "service_description"  : string
    "service_name" : string = "perfSONARBUOY MA"
    "service_type" : string = "MA"
};


type perfsonar_ma_endpoint = {
    "module" : string = "perfSONAR_PS::Services::MA::perfSONARBUOY"
    "name" : string
    "buoy" : perfsonarbuoy
};

type buoydaemon_port = {
    "port" : type_port = 8085
    "endpoint" : perfsonar_ma_endpoint[]
};

type buoydaemon = {
    "ports" : buoydaemon_port[]
    "reaper_interval" : long(0..) = 20
    # gLS Based registration
    "root_hints_file" ? string
    "root_hints_url" ? type_absoluteURI
    "disable_echo" : boolean = false
    "ls_instance" : type_absoluteURI = "http://localhost:9995/perfsonar_PS/services/hLS"
    "ls_registration_interval" : long(0..) = 60
    "max_worker_lifetime" : long(0..) = 300
    "max_worker_processes" : long(0..) = 30
    "pid_dir" : string =  "/var/lib/perfsonar/perfsonarbuoy_ma"
    "pid_file" : string = "perfsonarbuoy_ma.pid"
};


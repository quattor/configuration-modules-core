declaration template metaconfig/perfsonar/lookup/daemon/schema;

include 'pan/types';

type ls_gls = {
    "root" : boolean = false
    "ls_ttl" : long(0..) = 5760
    "ls_registration_interval" ? long(0..)
    "maintenance_interval" : long(0..) =  120
    "metadata_db_file" : string = "glsstore.dbxml"
    "metadata_summary_db_file"  : string = "glsstore-summary.dbxml"
    "metadata_db_name" : string = "/var/lib/perfsonar/lookup_service/xmldb"
    "service_accesspoint" : type_URI = "http://localhost:9995/perfsonar_PS/services/hLS"
    "service_description" : string
    "service_name" : string
    "service_type" : string = "hLS"
};

type ls_endpoint = {
    "gls" : ls_gls[]
    "disable" : boolean = false
    "module" : string = "perfSONAR_PS::Services::LS::gLS"
    "name" : string
};



type ls_port = {
    "endpoint" : ls_endpoint[]
    "portnum" : type_port = 9995
};

type ls_daemon = {
    "port" : ls_port[]
    "ls_registration_interval" ? long(0..)
    "disable_echo" : boolean = false
    "root_hints_url" ? type_URI = "http://www.perfsonar.net/gls.root.hints"
    "root_hints_file" ? string = "/var/lib/perfsonar/lookup_service/hls.root.hints"
    "reaper_interval" : long(0..) = 20
    "max_worker_lifetime" :  long(0..) = 300
    "max_worker_processes" : long(0..) = 30
    "pid_dir" : string = "/var/run"
    "pid_file" : string = "lookup_service.pid"
};


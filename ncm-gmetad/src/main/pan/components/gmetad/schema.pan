# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/gmetad/schema;

include 'quattor/schema';

type structure_component_gmetad_data_source_host = {
    "address" : type_hostname
    "port" ? type_port
};

type structure_component_gmetad_data_source = {
    "name" : string
    "polling_interval" ? long(1..)
    "host" ? structure_component_gmetad_data_source_host[]
};

type structure_component_gmetad = {
    include structure_component
    "debug_level" ? long(0..)
    "data_source" : structure_component_gmetad_data_source[]
    "scalability" ? string with match(SELF, "true|false")
    "gridname" ? string
    "authorithy" ? type_absoluteURI
    "trusted_hosts" ? type_hostname[]
    "all_trusted" ? string with match(SELF, "true|false")
    "setuid" ? string with match(SELF, "true|false")
    "setuid_username" ? string
    "xml_port" ? type_port
    "interactive_port" ? type_port
    "server_threads" ? long(1..)
    "rrd_rootdir" ? string
    "file" : string                    # location of the configuration file
                                                    # differs between Ganglia 3.0 and 3.1
};

bind "/software/components/gmetad" = structure_component_gmetad;

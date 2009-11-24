# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/pacemaker
#
#
#
############################################################

declaration template components/pacemaker/schema;

include { 'quattor/schema' };


type component_ha_type = {
    
    "logfacility" ? string ## deprecated
    
    "use_logd" : string
    
    "keepalive" : long(0..)
    "deadtime" : long(0..)
    "warntime" : long(0..)
    "initdead" : long(0..)

    "auto_failback" ? string

    "udpport" : long(0..)

    "authkey" : string

    "nodes" : string[]

    "communication" : string[]

    "watchdog" ? string

    "ping" ? long(0..)
    "baud" ? long(0..)
    
    "serial" ? string
    
    "respawn" ? string
    
    "hb_path" ? string
    
    "crm" ?  string
    
};

type component_crm_resource = {
    "primitive" ? string[]
    "monitor" ? string[]
    "group" ? string[]
    "clone" ? string[]
    "master" ? string[]
};

type component_crm_constraint = {
    "location" ? string[]
    "colocation" ? string[]
    "order" ? string[]
};

type component_crm_attributes = {
    "property" ? string[]
    "rsc_defaults" ? string[]
    "op_defaults" ? string[]
};


type component_crm_type = {
    "resource" ? component_crm_resource
    "constraint" ? component_crm_constraint
    "attributes" ? component_crm_attributes
};

type component_pacemaker_type = {
    include structure_component
    include structure_component_dependency

    "ha" : component_ha_type
    "crm" : component_crm_type
};

bind "/software/components/pacemaker" = component_pacemaker_type;

declaration template metaconfig/keepalived/schema;

include 'pan/types';

@documentation{
    The global_defs section
}
type keepalived_service_global = {
    'router_id' : string
};

@documentation{
    The vrrp_script section
}
type keepalived_service_vrrpscript = {
    'name' : string
    'script' : string
    'interval' : long = 2
    'weight' : long = 2
};

@documentation{
    The virtual_ipaddress section of the vrrp_instance
}
type keepalived_service_vip = {
    'ipaddress' : string
    'interface' : string
    'broadcast' ? type_ip
};

@documentation{
    The vrrp_instance configuration
}
type keepalived_service_vrrpinstance_config = {
    'virtual_router_id' : long
    'advert_int' : long = 1
    'priority' : long = 100
    'state' : choice("MASTER", "BACKUP")
    'interface' : string
};

@documentation{
    The vrrp_instance section
}
type keepalived_service_vrrpinstance = {
    'name' : string
    'config' : keepalived_service_vrrpinstance_config
    'virtual_ipaddresses' : keepalived_service_vip[]
    'track_scripts' ? string[]
    'unicast_peer' ? type_ip[]
    'unicast_src_ip' ? type_ip
    'virtual_routes' ? string[]
    'track_interface' ? string[]
};

@documentation{
    The keepalived notify type
}
type keepalived_notify_script = {
    'script' : absolute_file_path
    'args' ? string_trimmed[]
};

@documentation{
    The vrrp_sync_group section
}
type keepalived_service_vrrpsyncgroup = {
    'group' : string[]
    'notify_master' ? keepalived_notify_script
    'notify_backup' ? keepalived_notify_script
    'notify_fault' ? keepalived_notify_script
};

@documentation{
    Keepalived config
    See: http://keepalived.org/
}
type keepalived_service = {
    'global_defs' ? keepalived_service_global
    'vrrp_scripts' ? keepalived_service_vrrpscript[]
    'vrrp_instances' : keepalived_service_vrrpinstance[]
    'vrrp_sync_groups' ? keepalived_service_vrrpsyncgroup{}
};

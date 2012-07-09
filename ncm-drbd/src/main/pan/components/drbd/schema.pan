# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/drbd
#
#
############################################################

declaration template components/drbd/schema;

include { 'quattor/schema' };

#
# The following types and fields are taken from the documentation
# of /etc/drbd.conf for DRBD version 0.7
#

type component_drbd_global_type = {
    "minor_count" ? long(1..255)
    "dialog_refresh" ? long(0..)
    "disable_io_hints" ? string
};

type component_drbd_resource_host_type = {
    "hostname" : string with is_hostname(SELF)
    "device" : string
    "disk" : string
    "address" : string with is_hostport(SELF)
    "meta_disk" : string
};

type component_drbd_resource_startup_type = {
    "wfc_timeout" ? long(0..)
    "degr_wfc_timeout" ? long(0..)
};

type component_drbd_resource_syncer_type = {
    "rate" ? string
    "group" ? long
    "al_extents" ? long(7..3843)
};

type component_drbd_resource_net_type = {
    "sndbuf_size" ? string       # If nothing specified, DRBD is using 128k
    "timeout" ? long(1..)        # units of 0.1 sec
    "connect_int" ? long(1..)    # unit of 1 sec
    "ping_int" ? long(1..)       # unit of 1 sec
    "max_buffers" ? long(32..)   # unit is PAGE_SIZE ~4 kB
    "max_epoch_size" ? long
    "unplug_watermark" ? long(16..131072)
    "ko_count" ? long(0..)
    "on_disconnect" ? string with match(SELF, 'stand_alone|reconnect|freeze_io')
};

type component_drbd_resource_disk_type = {
    "on_io_error" ? string
};

type component_drbd_resource_type = {
    "protocol" : string(1) with match(SELF, 'A|B|C')
    "hosts" : component_drbd_resource_host_type[2]
    
    "primary_host" ? long(0..1)
    
    "incon_degr_cmd" ? string # no longer supported in DRBD 8
    "startup" ? component_drbd_resource_startup_type
    "syncer" ?component_drbd_resource_syncer_type
    "net" ? component_drbd_resource_net_type
    "disk" ? component_drbd_resource_disk_type
};

type component_drbd_type = {
    include structure_component

    "global"           ? component_drbd_global_type
    "resource"         : component_drbd_resource_type{}
    
    "reconfigure"      ? boolean
    "force_primary"    ? boolean
};

bind "/software/components/drbd" = component_drbd_type;

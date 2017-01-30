# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/autofs/schema;

include 'quattor/types/component';

type autofs_conf_common = {
};

type autofs_conf_autofs = {
    include autofs_conf_common
    "timeout" ? long(0..)
    "negative_timeout" ? long(0..)
    "mount_wait" ? long(0..)
    "umount_wait" ? long(0..)
    "browse_mode" ? boolean
    "append_options" ? boolean
    "logging" ? string with match(SELF, '^(none|verbose|debug)$')
};

type autofs_conf_amd = {
    include autofs_conf_common
    "dismount_interval" ? long(0..)
    "map_type" ? string with match(SELF, '^(file|nis|ldap)$')
    "autofs_use_lofs" ? boolean
};

type autofs_conf = {
    "autofs" ? autofs_conf_autofs
    "amd" ? autofs_conf_amd
    "mountpoints" ? autofs_conf_amd{}
};

type autofs_mapentry_type = {
    # TODO add new options like nfs options dict instead of random string
    "options" ? string
    "location" : string
};

type autofs_map_type = {
    "enabled" : boolean = true
    "preserve" : boolean = true # "Preserve existing entries not overwritten by config"
    "type" : string with match(SELF, "^(direct|file|program|yp|nisplus|hesiod|userdir|ldap)$")
    "mapname" : string
    "mountpoint" ? string
    "mpaliases" ? string[] # mount point aliases (deprecated) # TODO add deprecation warning?
    # TODO add new options like nfs options dict instead of random string
    "options" ? string
    "entries" ? autofs_mapentry_type{}
};

type component_autofs_type = {
    include structure_component
    "preserveMaster" : boolean = true # "Preserve local changes to master map"
    "maps" : autofs_map_type{}
    "conf" ? autofs_conf
};




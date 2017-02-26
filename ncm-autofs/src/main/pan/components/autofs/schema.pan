${componentschema}

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
    @{Specific mount options to be used with this entry.}
    "options" ? string
    @{NFS server name/path associated with this entry.}
    "location" : string
};

type autofs_map_type = {
    @{If false, ignore entries for this map (no change made).}
    "enabled" : boolean = true
    @{This flag indicated if local changes to the map must be
      preserved (true) or not (false).}
    "preserve" : boolean = true
    @{Map type. Supported types are : direct, file, program, yp, nisplus, hesiod, userdir and ldap.
      Only direct, file and program map contents can be managed by this component.}
    "type" : string with match(SELF, "^(direct|file|program|yp|nisplus|hesiod|userdir|ldap)$")
    @{Map name. If not defined, a default name is build (/etc/auto suffixed by map entry name).}
    "mapname" : string
    @{Mount point associated with this map.}
    "mountpoint" ? string
    @{mount point aliases (deprecated)}
    "mpaliases" ? string[] with {deprecated(0, 'mountpoint aliases is deprecated'); true; }
    # TODO add new options like nfs options dict instead of random string
    @{Mount options to be used with this map.}
    "options" ? string
    @{One entry per filesystem to mount. The key is used to build the mount point. The actual
    mount point depends on map type.}
    "entries" ? autofs_mapentry_type{}
};

type autofs_component = {
    include structure_component
    @{This flag indicated if local changes to master map
      must be preserved (true) or not (false).}
    "preserveMaster" : boolean = true
    @{This resource contains one entry per autofs map to manage. The dict key is
    mainly an internal name but it will be used to build the default map name.}
    "maps" : autofs_map_type{}
    "conf" ? autofs_conf
};

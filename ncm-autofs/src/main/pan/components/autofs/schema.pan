# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/autofs
#
#
#
############################################################

declaration template components/autofs/schema;

include { 'quattor/schema' };

type autofs_mapentry_type = {
  "options"     ? string
  "location"    : string
};

type autofs_map_type = {
  "enabled"     : boolean = true
  "preserve"    : boolean = true # "Preserve existing entries not overwritten by config"
  "type"        : string with match(SELF,"direct|file|program|yp|nisplus|hesiod|userdir|ldap")
  "mapname"     ? string
  "mountpoint"  ? string
  "mpaliases"   ? string[]
  "options"     ? string
  "entries"	? autofs_mapentry_type{}
};

type component_autofs_type = {
  include structure_component
  "preserveMaster" : boolean = true # "Preserve local changes to master map"
  "maps"	       : autofs_map_type{}
};

bind "/software/components/autofs" = component_autofs_type;



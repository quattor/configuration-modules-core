# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/altlogrotate/schema;

include quattor/schema;
include pan/types;

type structure_altlogrotate_scripts = {
    'prerotate'   ? string
    'postrotate'  ? string
    'firstaction' ? string
    'lastaction'  ? string
};

type structure_altlogrotate_create_params = {
    'mode'  : string with match(self, '0[0-7]{3,3}')
    'owner' : string
    'group' : string
};

type structure_altlogrotate_logrot = {
    'pattern'         ? string
    'global'          ? boolean
    'overwrite'       ? boolean

    'include'         ? string

    'compress'        ? boolean
    'copy'            ? boolean
    'copytruncate'    ? boolean
    'delaycompress'   ? boolean
    'ifempty'         ? boolean
    'missingok'       ? boolean
    'sharedscripts'   ? boolean

    'compresscmd'     ? string
    'uncompresscmd'   ? string
    'compressext'     ? string
    'compressoptions' ? string

    'create'          ? boolean
    'createparams'    ? structure_altlogrotate_create_params

    'extension'       ? string

    'mail'            ? type_email
    'nomail'          ? boolean
    'mailselect'      ? string with match(self, 'first|last')

    'olddir'          ? string
    'noolddir'        ? boolean

    'rotate'          ? long(0..)
    'start'           ? long(0..)

    'size'            ? string with match(self, '\d+[kM]?')

    'taboo_replace'   ? boolean
    'tabooext'        ? string[] 

    'frequency'       ? string with match(self, 'daily|weekly|monthly')

    'scripts'         ? structure_altlogrotate_scripts
};

type component_altlogrotate = {
    include structure_component
    'configFile' : string = '/etc/logrotate.conf'
    'configDir'  : string = '/etc/logrotate.d'
    'entries'    ? structure_altlogrotate_logrot{}
};

type '/software/components/altlogrotate' = component_altlogrotate;

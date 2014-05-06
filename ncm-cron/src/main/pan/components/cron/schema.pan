# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}


declaration template components/cron/schema;

include { 'quattor/schema' };

# Function to check that other log properties are not present if disabled=yes
function structure_cron_log_valid = {
  if ( is_defined(SELF['disabled']) && SELF['disabled'] ) {
    if ( is_defined(SELF['name']) ||
         is_defined(SELF['owner']) ||
         is_defined(SELF['mode']) ) {
           error('cron log file properties are present despite log file creation has been disabled.');
         };
  };
  true;
};

type structure_cron_syslog = {
    'facility'  : string = 'user'
    'level'     : string = 'notice'
    'tagprefix' : string = 'ncm-cron.' with (!match(SELF,'\s')) # prefix tag
    'tag'       ? string with (!match(SELF,'\s')) # use this fixed tag instead of name
};

type structure_cron_log = {
    'disabled'  ? boolean
    'name'      ? string
    'owner'     ? string
    'mode'      ? string
} with structure_cron_log_valid(SELF);

type structure_cron_timing = {
    'minute'    ? string
    'hour'      ? string
    'day'       ? string
    'month'     ? string
    'weekday'   ? string
    'smear'     ? long(0..1440)
};

type structure_cron = {
    'name'      : string
    'user'      ? string
    'group'     ? string
    'frequency' ? string
    'timing'    ? structure_cron_timing
    'command'   : string
    'comment'   ? string
    'env'       ? string{}
    'log'       ? structure_cron_log
    'syslog'    ? structure_cron_syslog
} with { if(exists(SELF['log']) && exists(SELF['syslog'])) {
            error("At most one of log or syslog can be defined");
         } else {
            true;
         }
       };

type component_cron = {
    include structure_component
    'entries' ? structure_cron[]
    'deny'    ? string[]
    'allow'   ? string[]
    # required for multi os
    'securitypath' : string = '/etc' # Linux default
};

bind '/software/components/cron' = component_cron;



# ${license-info}
# ${developer-info}
# ${author-info}


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
};

type component_cron = {
    include structure_component
    'entries' ? structure_cron[]
    'deny'    ? string[]
    'allow'   ? string[]
    'securitypath' : string = '/etc'
};

bind '/software/components/cron' = component_cron;

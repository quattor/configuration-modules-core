# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/cron/schema;

include { 'quattor/schema' };

type structure_cron_log = {
    'name'      ? string
    'owner'     ? string
    'mode'      ? string
};

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
};

bind '/software/components/cron' = component_cron;



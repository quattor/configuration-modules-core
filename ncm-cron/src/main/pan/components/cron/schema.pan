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

type structure_cron = {
    'name'      : string
    'user'      ? string
    'group'     ? string
    'frequency' : string
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



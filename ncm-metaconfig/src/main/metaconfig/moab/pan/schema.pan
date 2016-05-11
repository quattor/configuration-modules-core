declaration template metaconfig/moab/schema;

include 'pan/types';

@documentation{
    The legacy moab service corrsponds to the old moab component schema, with only difference
        include is a list of absolute filenames, and does not support contents or ok
}
type moab_service_legacy = {
    'sched' ? string[]{}
    'rm' ? string[]{}
    'am' ? string[]{}
    'id' ? string[]{}
    'user' ? string[]{}
    'group' ? string[]{}
    'node'  ? string[]{}
    'account' ? string[]{}
    'class'  ? string[]{}
    'qos'  ? string[]{}
    'main' : string{}
    'priority' ? string{}
    'include' ? string[]
};
